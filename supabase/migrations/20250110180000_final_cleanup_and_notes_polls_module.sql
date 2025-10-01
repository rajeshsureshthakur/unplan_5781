-- Location: supabase/migrations/20250110180000_final_cleanup_and_notes_polls_module.sql
-- Schema Analysis: Existing tables: user_profiles, groups, group_members, events, expenses
-- Integration Type: addition (notes & polls) + destructive (cleanup dummy data)
-- Dependencies: user_profiles, groups

-- ================================================================================
-- STEP 1: ADD MISSING NOTES & POLLS MODULE
-- ================================================================================

-- Create enum types for notes and polls
CREATE TYPE public.reaction_type AS ENUM ('like', 'love', 'laugh', 'wow', 'angry', 'sad', 'thumbs_up');
CREATE TYPE public.note_status AS ENUM ('active', 'archived', 'deleted');
CREATE TYPE public.poll_status AS ENUM ('active', 'closed', 'draft');

-- Notes table
CREATE TABLE public.notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    author_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    status public.note_status DEFAULT 'active'::public.note_status,
    is_pinned BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Polls table
CREATE TABLE public.polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    author_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    description TEXT,
    status public.poll_status DEFAULT 'active'::public.poll_status,
    is_multiple_choice BOOLEAN DEFAULT false,
    is_anonymous BOOLEAN DEFAULT false,
    closes_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Poll options table
CREATE TABLE public.poll_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE,
    option_text TEXT NOT NULL,
    option_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Poll votes table
CREATE TABLE public.poll_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE,
    option_id UUID REFERENCES public.poll_options(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Reactions table (for both notes and polls)
CREATE TABLE public.reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    target_type TEXT NOT NULL CHECK (target_type IN ('note', 'poll')),
    target_id UUID NOT NULL,
    reaction_emoji TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ================================================================================
-- STEP 2: CREATE INDEXES
-- ================================================================================

-- Notes indexes
CREATE INDEX idx_notes_group_id ON public.notes(group_id);
CREATE INDEX idx_notes_author_id ON public.notes(author_id);
CREATE INDEX idx_notes_status ON public.notes(status);
CREATE INDEX idx_notes_created_at ON public.notes(created_at DESC);

-- Polls indexes
CREATE INDEX idx_polls_group_id ON public.polls(group_id);
CREATE INDEX idx_polls_author_id ON public.polls(author_id);
CREATE INDEX idx_polls_status ON public.polls(status);
CREATE INDEX idx_polls_created_at ON public.polls(created_at DESC);

-- Poll options indexes
CREATE INDEX idx_poll_options_poll_id ON public.poll_options(poll_id);
CREATE INDEX idx_poll_options_order ON public.poll_options(poll_id, option_order);

-- Poll votes indexes
CREATE INDEX idx_poll_votes_poll_id ON public.poll_votes(poll_id);
CREATE INDEX idx_poll_votes_user_id ON public.poll_votes(user_id);
CREATE UNIQUE INDEX idx_poll_votes_unique_single ON public.poll_votes(poll_id, user_id, option_id);

-- Reactions indexes
CREATE INDEX idx_reactions_target ON public.reactions(target_type, target_id);
CREATE INDEX idx_reactions_user_id ON public.reactions(user_id);
CREATE UNIQUE INDEX idx_reactions_unique ON public.reactions(user_id, target_type, target_id, reaction_emoji);

-- ================================================================================
-- STEP 3: ENABLE RLS
-- ================================================================================

ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;

-- ================================================================================
-- STEP 4: CREATE RLS POLICIES
-- ================================================================================

-- Notes policies - Pattern 2: Simple User Ownership via group membership
CREATE POLICY "users_access_group_notes"
ON public.notes
FOR ALL
TO authenticated
USING (
    group_id IN (
        SELECT gm.group_id FROM public.group_members gm 
        WHERE gm.user_id = auth.uid()
    )
)
WITH CHECK (
    group_id IN (
        SELECT gm.group_id FROM public.group_members gm 
        WHERE gm.user_id = auth.uid()
    )
    AND author_id = auth.uid()
);

-- Polls policies - Pattern 2: Simple User Ownership via group membership
CREATE POLICY "users_access_group_polls"
ON public.polls
FOR ALL
TO authenticated
USING (
    group_id IN (
        SELECT gm.group_id FROM public.group_members gm 
        WHERE gm.user_id = auth.uid()
    )
)
WITH CHECK (
    group_id IN (
        SELECT gm.group_id FROM public.group_members gm 
        WHERE gm.user_id = auth.uid()
    )
    AND author_id = auth.uid()
);

-- Poll options policies - inherit from poll access
CREATE POLICY "users_access_poll_options"
ON public.poll_options
FOR ALL
TO authenticated
USING (
    poll_id IN (
        SELECT p.id FROM public.polls p
        WHERE p.group_id IN (
            SELECT gm.group_id FROM public.group_members gm 
            WHERE gm.user_id = auth.uid()
        )
    )
)
WITH CHECK (
    poll_id IN (
        SELECT p.id FROM public.polls p
        WHERE p.group_id IN (
            SELECT gm.group_id FROM public.group_members gm 
            WHERE gm.user_id = auth.uid()
        )
        AND p.author_id = auth.uid()
    )
);

-- Poll votes policies - Pattern 2: Simple User Ownership
CREATE POLICY "users_manage_own_poll_votes"
ON public.poll_votes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Reactions policies - Pattern 2: Simple User Ownership
CREATE POLICY "users_manage_own_reactions"
ON public.reactions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ================================================================================
-- STEP 5: CREATE UTILITY FUNCTIONS
-- ================================================================================

-- Function to get poll results
CREATE OR REPLACE FUNCTION public.get_poll_results(poll_uuid UUID)
RETURNS TABLE(
    option_id UUID,
    option_text TEXT,
    vote_count BIGINT,
    percentage NUMERIC
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    po.id as option_id,
    po.option_text,
    COALESCE(vote_counts.vote_count, 0) as vote_count,
    CASE 
        WHEN total_votes.total > 0 THEN 
            ROUND((COALESCE(vote_counts.vote_count, 0)::NUMERIC / total_votes.total) * 100, 1)
        ELSE 0
    END as percentage
FROM public.poll_options po
LEFT JOIN (
    SELECT option_id, COUNT(*) as vote_count
    FROM public.poll_votes
    WHERE poll_id = poll_uuid
    GROUP BY option_id
) vote_counts ON po.id = vote_counts.option_id
CROSS JOIN (
    SELECT COUNT(*) as total
    FROM public.poll_votes
    WHERE poll_id = poll_uuid
) total_votes
WHERE po.poll_id = poll_uuid
ORDER BY po.option_order;
$$;

-- Function to check if user can vote on poll
CREATE OR REPLACE FUNCTION public.can_user_vote_on_poll(poll_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.polls p
    JOIN public.group_members gm ON p.group_id = gm.group_id
    WHERE p.id = poll_uuid
    AND gm.user_id = user_uuid
    AND p.status = 'active'
    AND (p.closes_at IS NULL OR p.closes_at > CURRENT_TIMESTAMP)
);
$$;

-- ================================================================================
-- STEP 6: CLEANUP ALL EXISTING DUMMY DATA
-- ================================================================================

-- Create comprehensive cleanup function
CREATE OR REPLACE FUNCTION public.cleanup_all_demo_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete in dependency order (children first)
    
    -- Delete reactions
    DELETE FROM public.reactions;
    
    -- Delete poll votes
    DELETE FROM public.poll_votes;
    
    -- Delete poll options  
    DELETE FROM public.poll_options;
    
    -- Delete polls
    DELETE FROM public.polls;
    
    -- Delete notes
    DELETE FROM public.notes;
    
    -- Delete expenses (referencing events and user_profiles)
    DELETE FROM public.expenses;
    
    -- Delete events (referencing groups and user_profiles)  
    DELETE FROM public.events;
    
    -- Delete group members (junction table)
    DELETE FROM public.group_members;
    
    -- Delete groups (referencing user_profiles)
    DELETE FROM public.groups;
    
    -- Delete user profiles (keep the structure, delete demo data)
    DELETE FROM public.user_profiles WHERE email = 'demo@unplan.app';
    
    RAISE NOTICE 'All demo data cleaned successfully. Database is now ready for fresh start.';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup encountered an error: %', SQLERRM;
        -- Continue execution even if cleanup fails
END;
$$;

-- Execute the cleanup
SELECT public.cleanup_all_demo_data();

-- ================================================================================
-- STEP 7: CREATE TRIGGERS FOR AUTOMATIC TIMESTAMPS
-- ================================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Add triggers for updated_at
CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON public.notes
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_polls_updated_at
    BEFORE UPDATE ON public.polls
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();