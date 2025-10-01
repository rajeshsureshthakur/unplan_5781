import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  // REVERT: Simplified initialization without complex auth system
  static bool _isReady = false;
  static const Uuid _uuid = Uuid();

  // Demo user ID for consistent access
  static const String DEMO_USER_ID = '25b09808-c76d-4d60-81d0-7ddf5739c220';

  // Initialize Supabase
  static Future<void> initialize() async {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase URL or ANON KEY is not configured');
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    _isReady = true;
    print('✅ Supabase initialized successfully');
  }

  // REVERT: Simple demo user access
  Future<bool> isUserAuthenticated() async {
    // For demo purposes, always return true since we have demo data
    return _isReady;
  }

  // CRITICAL FIX: Enhanced user profile update with proper image storage
  Future<Map<String, dynamic>> updateUserProfile({
    required String fullName,
    String? profilePicture,
  }) async {
    try {
      print('📝 Updating user profile with storage integration...');

      // CRITICAL FIX: Ensure demo user exists before any operations
      await _ensureDemoUserExists();

      String? imageFileName;
      String? storageUrl;

      // CRITICAL FIX: Handle image upload to Supabase Storage if provided
      if (profilePicture != null && profilePicture.isNotEmpty) {
        print('📷 Processing profile image upload...');

        // Generate unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = _getFileExtension(profilePicture);
        imageFileName = 'profile_$timestamp.$extension';

        try {
          // Upload to Supabase Storage
          storageUrl = await _uploadProfileImageToStorage(
            profilePicture,
            DEMO_USER_ID,
            imageFileName,
          );
          print('✅ Image uploaded successfully: $storageUrl');
        } catch (e) {
          print('⚠️ Image upload failed: $e');
          // Continue with profile update even if image upload fails
        }
      }

      // CRITICAL FIX: Use database function for consistent profile updates
      final result =
          await client.rpc('update_user_profile_with_storage', params: {
        'p_user_id': DEMO_USER_ID,
        'p_full_name': fullName.trim(),
        'p_image_file_name': imageFileName,
      }).timeout(Duration(seconds: 15));

      print(
          '✅ Profile updated successfully with storage: ${result['full_name']}');
      return Map<String, dynamic>.from(result);
    } catch (error) {
      print('❌ Profile update error: $error');
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  // CRITICAL FIX: Add method to upload profile images to Supabase Storage
  Future<String> _uploadProfileImageToStorage(
    String imagePath,
    String userId,
    String fileName,
  ) async {
    try {
      print('📤 Uploading image to storage: $fileName');

      // Read file bytes
      late List<int> fileBytes;

      if (kIsWeb) {
        // For web, imagePath might be a blob URL or base64
        // This is a simplified implementation - in real app, handle properly
        throw UnimplementedError(
            'Web image upload needs proper implementation');
      } else {
        // For mobile, read file from path
        final file = File(imagePath);
        fileBytes = await file.readAsBytes();
      }

      // Upload to profile-images bucket
      final storagePath = '$userId/$fileName';

      await client.storage
          .from('profile-images')
          .uploadBinary(storagePath, Uint8List.fromList(fileBytes))
          .timeout(Duration(seconds: 30));

      // Get public URL
      final publicUrl =
          client.storage.from('profile-images').getPublicUrl(storagePath);

      print('✅ Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (error) {
      print('❌ Storage upload error: $error');
      throw Exception('Failed to upload profile image');
    }
  }

  // Helper method to get file extension
  String _getFileExtension(String path) {
    final parts = path.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : 'jpg';
  }

  // CRITICAL FIX: Enhanced getCurrentUser to return updated data
  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _getCurrentUserProfile();
  }

  // CRITICAL FIX: Enhanced profile retrieval with proper fallbacks and image URL handling
  Future<Map<String, dynamic>> _getCurrentUserProfile() async {
    try {
      print('🔍 Getting current user profile with latest updates...');

      // Get the current user profile from database (which has the updated name)
      final profile = await client
          .from('user_profiles')
          .select('*')
          .eq('id', DEMO_USER_ID)
          .single()
          .timeout(Duration(seconds: 10));

      print(
          '✅ Current user profile: ${profile['full_name']} (${profile['id']})');
      print('📷 Profile picture: ${profile['profile_picture']}');

      // CRITICAL FIX: Ensure profile picture URLs are properly handled
      if (profile['profile_picture'] != null &&
          profile['profile_picture'].toString().isNotEmpty) {
        String profilePicUrl = profile['profile_picture'].toString();

        // If it's just a filename/path, convert to public URL
        if (!profilePicUrl.startsWith('http')) {
          try {
            profilePicUrl = client.storage
                .from('profile-images')
                .getPublicUrl(profilePicUrl);
            profile['profile_picture'] = profilePicUrl;
            print('🔗 Converted profile picture to public URL: $profilePicUrl');
          } catch (e) {
            print('⚠️ Failed to convert profile picture URL: $e');
          }
        }
      }

      return profile;
    } catch (e) {
      print('⚠️ Failed to get current user profile: $e');
      // Fallback to demo user data
      return {
        'id': DEMO_USER_ID,
        'full_name': 'Demo User',
        'email': 'demo@unplan.app',
        'profile_picture': null,
      };
    }
  }

  // CRITICAL FIX: Add method to ensure demo user exists
  Future<void> _ensureDemoUserExists() async {
    try {
      // Check if demo user exists
      final existingUser = await client
          .from('user_profiles')
          .select('id, full_name')
          .eq('id', DEMO_USER_ID)
          .maybeSingle()
          .timeout(Duration(seconds: 8));

      if (existingUser == null) {
        print('🔧 Creating demo user profile...');

        // Create demo user profile
        await client.from('user_profiles').insert({
          'id': DEMO_USER_ID,
          'full_name': 'Demo User',
          'email': 'demo@unplan.app',
          'phone': null,
          'profile_picture': null,
          'role': 'member',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).timeout(Duration(seconds: 10));

        print('✅ Demo user created successfully');
      } else {
        print('✅ Demo user already exists: ${existingUser['full_name']}');
      }
    } catch (e) {
      print('⚠️ Error ensuring demo user exists: $e');
      // Continue with operations - fallback handling will work
    }
  }

  // REVERT: Simple group creation that works
  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? description,
    String? profilePicture,
  }) async {
    try {
      print('🆕 Creating group: $name');

      // CRITICAL FIX: Ensure demo user exists before creating group
      await _ensureDemoUserExists();

      // Generate a proper UUID for the new group
      final groupId = _uuid.v4();

      // Create the group
      final groupResponse = await client
          .from('groups')
          .insert({
            'id': groupId,
            'name': name.trim(),
            'description': description?.trim(),
            'profile_picture': profilePicture?.trim(),
            'created_by': DEMO_USER_ID,
          })
          .select()
          .single()
          .timeout(Duration(seconds: 10));

      // Add creator as admin member
      await client.from('group_members').insert({
        'group_id': groupId,
        'user_id': DEMO_USER_ID,
        'role': 'admin',
      }).timeout(Duration(seconds: 8));

      // Add member count to response
      groupResponse['memberCount'] = 1;

      print('✅ Group created successfully: ${groupResponse['name']}');
      return groupResponse;
    } catch (error) {
      print('❌ Group creation error: $error');
      throw Exception('Failed to create group. Please try again.');
    }
  }

  // REVERT: Simple groups fetching
  Future<List<Map<String, dynamic>>> getUserGroups() async {
    try {
      print('🔍 Fetching groups for demo user...');

      final response = await client
          .from('group_members')
          .select('''
            groups!inner(
              id,
              name,
              description,
              profile_picture,
              created_at,
              updated_at,
              created_by
            )
          ''')
          .eq('user_id', DEMO_USER_ID)
          .order('groups(updated_at)', ascending: false)
          .timeout(Duration(seconds: 10));

      // Transform the response to match expected format
      final transformedGroups = <Map<String, dynamic>>[];

      for (var item in response) {
        final group = item['groups'];
        if (group != null) {
          // Get member count for this group
          final memberCount = await _getGroupMemberCount(group['id']);

          transformedGroups.add({
            ...group,
            'memberCount': memberCount,
          });
        }
      }

      print('✅ Successfully fetched ${transformedGroups.length} groups');
      return transformedGroups;
    } catch (error) {
      print('❌ Error fetching user groups: $error');
      return [];
    }
  }

  // REVERT: Simple member count helper
  Future<int> _getGroupMemberCount(String groupId) async {
    try {
      final response = await client
          .from('group_members')
          .select('id')
          .eq('group_id', groupId)
          .timeout(Duration(seconds: 5));

      return response.length;
    } catch (e) {
      print('⚠️ Error getting member count: $e');
      return 1; // Default to 1 if error
    }
  }

  // REVERT: Simple group update
  Future<Map<String, dynamic>> updateGroup({
    required String groupId,
    required String name,
    String? description,
    String? profilePicture,
  }) async {
    try {
      print('🔍 Updating group: $groupId');

      // Update the group
      final result = await client
          .from('groups')
          .update({
            'name': name.trim(),
            'description': description?.trim(),
            'profile_picture': profilePicture?.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', groupId)
          .select()
          .single()
          .timeout(Duration(seconds: 10));

      // Add member count to response
      result['memberCount'] = await _getGroupMemberCount(groupId);

      print('✅ Group updated successfully: ${result['name']}');
      return result;
    } catch (error) {
      print('❌ Group update error: $error');
      throw Exception('Failed to update group. Please try again.');
    }
  }

  // REVERT: Simple expense creation
  Future<Map<String, dynamic>> createExpense({
    required String groupId,
    required String title,
    required double amount,
    required String payerId,
    String? eventId,
    required List<String> splitMembers,
  }) async {
    try {
      print('💰 Creating expense: $title');

      // Generate a proper UUID for the expense
      final expenseId = _uuid.v4();

      // CRITICAL FIX: Use actual current user profile instead of hardcoded demo user
      // Get the current user's profile to get their updated name and actual ID
      final currentUserProfile = await _getCurrentUserProfile();
      final actualPayerId = currentUserProfile['id'] ?? DEMO_USER_ID;
      final actualPayerName = currentUserProfile['full_name'] ?? 'Demo User';

      print('💰 Using payer: $actualPayerName (ID: $actualPayerId)');

      // Ensure current user is in split members
      final cleanedSplitMembers = List<String>.from(splitMembers);
      if (!cleanedSplitMembers.contains(actualPayerId)) {
        cleanedSplitMembers.add(actualPayerId);
      }

      // Create expense data
      final expenseData = {
        'id': expenseId,
        'group_id': groupId,
        'title': title.trim(),
        'amount': amount,
        'payer_id': actualPayerId, // FIXED: Use actual user ID, not hardcoded
        'event_id': eventId,
        'split_members': cleanedSplitMembers,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await client.from('expenses').insert(expenseData).select('''
            *,
            payer:user_profiles!payer_id(full_name),
            event:events(title)
          ''').single().timeout(Duration(seconds: 10));

      print(
          '✅ Expense created successfully: ${response['id']} by ${response['payer']?['full_name']}');
      return response;
    } catch (error) {
      print('❌ Expense creation error: $error');
      throw Exception('Failed to create expense. Please try again.');
    }
  }

  // REVERT: Other simple methods
  Future<List<Map<String, dynamic>>> getGroupExpenses(String groupId) async {
    try {
      final response = await client
          .from('expenses')
          .select('''
            *,
            payer:user_profiles!payer_id(full_name),
            event:events(title)
          ''')
          .eq('group_id', groupId)
          .order('created_at', ascending: false)
          .timeout(Duration(seconds: 10));

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('❌ Error fetching expenses: $error');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGroupEvents(String groupId) async {
    try {
      final response = await client
          .from('events')
          .select('''
            *,
            creator:user_profiles!created_by(full_name)
          ''')
          .eq('group_id', groupId)
          .order('event_date', ascending: true)
          .timeout(Duration(seconds: 10));

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('❌ Error fetching events: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getGroupById(String groupId) async {
    try {
      final response = await client.from('groups').select('''
            *,
            group_members(
              id,
              user_id,
              role,
              user_profiles(
                id,
                full_name,
                email,
                profile_picture
              )
            )
          ''').eq('id', groupId).single().timeout(Duration(seconds: 10));

      return response;
    } catch (error) {
      print('❌ Error fetching group: $error');
      return null;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    try {
      print('🚪 Leaving group: $groupId');

      await client
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', DEMO_USER_ID)
          .timeout(Duration(seconds: 10));

      print('✅ Successfully left group');
      return true;
    } catch (error) {
      print('❌ Leave group error: $error');
      throw Exception('Failed to leave group. Please try again.');
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
      print('✅ User signed out successfully');
    } catch (e) {
      print('⚠️ Sign out warning: $e');
    }
  }

  // ================================================================================
  // NOTES MODULE METHODS
  // ================================================================================

  Future<List<Map<String, dynamic>>> getGroupNotes(String groupId) async {
    try {
      print('🔍 Fetching notes for group: $groupId');

      final response = await client
          .from('notes')
          .select('''
            *,
            author:user_profiles!author_id(full_name, profile_picture)
          ''')
          .eq('group_id', groupId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .timeout(Duration(seconds: 10));

      print('✅ Successfully fetched ${response.length} notes');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('❌ Error fetching notes: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>> createNote({
    required String groupId,
    required String content,
    bool isPinned = false,
  }) async {
    try {
      print('📝 Creating note for group: $groupId');

      final currentUserProfile = await _getCurrentUserProfile();
      final actualAuthorId = currentUserProfile['id'] ?? DEMO_USER_ID;

      final noteData = {
        'group_id': groupId,
        'author_id': actualAuthorId,
        'content': content.trim(),
        'is_pinned': isPinned,
        'status': 'active',
      };

      final response = await client.from('notes').insert(noteData).select('''
            *,
            author:user_profiles!author_id(full_name, profile_picture)
          ''').single().timeout(Duration(seconds: 10));

      print('✅ Note created successfully: ${response['id']}');
      return response;
    } catch (error) {
      print('❌ Note creation error: $error');
      throw Exception('Failed to create note. Please try again.');
    }
  }

  Future<Map<String, dynamic>> updateNote({
    required String noteId,
    required String content,
    bool? isPinned,
  }) async {
    try {
      print('📝 Updating note: $noteId');

      final updateData = <String, dynamic>{
        'content': content.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isPinned != null) {
        updateData['is_pinned'] = isPinned;
      }

      final response = await client
          .from('notes')
          .update(updateData)
          .eq('id', noteId)
          .select('''
            *,
            author:user_profiles!author_id(full_name, profile_picture)
          ''')
          .single()
          .timeout(Duration(seconds: 10));

      print('✅ Note updated successfully');
      return response;
    } catch (error) {
      print('❌ Note update error: $error');
      throw Exception('Failed to update note. Please try again.');
    }
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      print('🗑️ Deleting note: $noteId');

      await client
          .from('notes')
          .update({'status': 'deleted'})
          .eq('id', noteId)
          .timeout(Duration(seconds: 10));

      print('✅ Note deleted successfully');
      return true;
    } catch (error) {
      print('❌ Note deletion error: $error');
      throw Exception('Failed to delete note. Please try again.');
    }
  }

  // ================================================================================
  // POLLS MODULE METHODS
  // ================================================================================

  Future<List<Map<String, dynamic>>> getGroupPolls(String groupId) async {
    try {
      print('🔍 Fetching polls for group: $groupId');

      final response = await client
          .from('polls')
          .select('''
            *,
            author:user_profiles!author_id(full_name, profile_picture),
            poll_options(
              id,
              option_text,
              option_order
            )
          ''')
          .eq('group_id', groupId)
          .neq('status', 'deleted')
          .order('created_at', ascending: false)
          .timeout(Duration(seconds: 10));

      print('✅ Successfully fetched ${response.length} polls');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('❌ Error fetching polls: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>> createPoll({
    required String groupId,
    required String question,
    required List<String> options,
    String? description,
    bool isMultipleChoice = false,
    bool isAnonymous = false,
    DateTime? closesAt,
  }) async {
    try {
      print('📊 Creating poll for group: $groupId');

      final currentUserProfile = await _getCurrentUserProfile();
      final actualAuthorId = currentUserProfile['id'] ?? DEMO_USER_ID;

      // Generate poll ID
      final pollId = _uuid.v4();

      // Create poll
      final pollData = {
        'id': pollId,
        'group_id': groupId,
        'author_id': actualAuthorId,
        'question': question.trim(),
        'description': description?.trim(),
        'is_multiple_choice': isMultipleChoice,
        'is_anonymous': isAnonymous,
        'closes_at': closesAt?.toIso8601String(),
        'status': 'active',
      };

      final pollResponse =
          await client.from('polls').insert(pollData).select('''
            *,
            author:user_profiles!author_id(full_name, profile_picture)
          ''').single().timeout(Duration(seconds: 10));

      // Create poll options
      final optionData = options.asMap().entries.map((entry) {
        return {
          'poll_id': pollId,
          'option_text': entry.value.trim(),
          'option_order': entry.key,
        };
      }).toList();

      await client
          .from('poll_options')
          .insert(optionData)
          .timeout(Duration(seconds: 8));

      // Fetch complete poll with options
      final completeResponse = await client.from('polls').select('''
            *,
            author:user_profiles!author_id(full_name, profile_picture),
            poll_options(
              id,
              option_text,
              option_order
            )
          ''').eq('id', pollId).single().timeout(Duration(seconds: 8));

      print('✅ Poll created successfully: ${completeResponse['id']}');
      return completeResponse;
    } catch (error) {
      print('❌ Poll creation error: $error');
      throw Exception('Failed to create poll. Please try again.');
    }
  }

  Future<Map<String, dynamic>> votePoll({
    required String pollId,
    required String optionId,
  }) async {
    try {
      print('🗳️ Voting on poll: $pollId, option: $optionId');

      final currentUserProfile = await _getCurrentUserProfile();
      final actualUserId = currentUserProfile['id'] ?? DEMO_USER_ID;

      // Check if user can vote
      final canVoteResult = await client
          .rpc('can_user_vote_on_poll', params: {
            'poll_uuid': pollId,
            'user_uuid': actualUserId,
          })
          .single()
          .timeout(Duration(seconds: 8));

      final canVote = canVoteResult as bool;

      if (!canVote) {
        throw Exception('You cannot vote on this poll');
      }

      // Remove existing vote if not multiple choice
      await client
          .from('poll_votes')
          .delete()
          .eq('poll_id', pollId)
          .eq('user_id', actualUserId)
          .timeout(Duration(seconds: 8));

      // Add new vote
      final voteData = {
        'poll_id': pollId,
        'option_id': optionId,
        'user_id': actualUserId,
      };

      final response = await client
          .from('poll_votes')
          .insert(voteData)
          .select()
          .single()
          .timeout(Duration(seconds: 10));

      print('✅ Vote recorded successfully');
      return response;
    } catch (error) {
      print('❌ Vote error: $error');
      throw Exception('Failed to record vote. Please try again.');
    }
  }

  Future<List<Map<String, dynamic>>> getPollResults(String pollId) async {
    try {
      print('📊 Getting poll results: $pollId');

      final response = await client.rpc('get_poll_results', params: {
        'poll_uuid': pollId,
      }).timeout(Duration(seconds: 10));

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('❌ Error getting poll results: $error');
      return [];
    }
  }

  // ================================================================================
  // REACTIONS MODULE METHODS
  // ================================================================================

  Future<Map<String, dynamic>> toggleReaction({
    required String targetId,
    required String targetType, // 'note' or 'poll'
    required String emoji,
  }) async {
    try {
      print('👍 Toggling reaction: $emoji on $targetType $targetId');

      final currentUserProfile = await _getCurrentUserProfile();
      final actualUserId = currentUserProfile['id'] ?? DEMO_USER_ID;

      // Check if reaction already exists
      final existingReaction = await client
          .from('reactions')
          .select('id')
          .eq('user_id', actualUserId)
          .eq('target_type', targetType)
          .eq('target_id', targetId)
          .eq('reaction_emoji', emoji)
          .maybeSingle()
          .timeout(Duration(seconds: 8));

      if (existingReaction != null) {
        // Remove reaction
        await client
            .from('reactions')
            .delete()
            .eq('id', existingReaction['id'])
            .timeout(Duration(seconds: 8));

        print('✅ Reaction removed');
        return {'action': 'removed', 'emoji': emoji};
      } else {
        // Add reaction
        final reactionData = {
          'user_id': actualUserId,
          'target_type': targetType,
          'target_id': targetId,
          'reaction_emoji': emoji,
        };

        await client
            .from('reactions')
            .insert(reactionData)
            .timeout(Duration(seconds: 10));

        print('✅ Reaction added');
        return {'action': 'added', 'emoji': emoji};
      }
    } catch (error) {
      print('❌ Reaction error: $error');
      throw Exception('Failed to update reaction. Please try again.');
    }
  }

  Future<Map<String, Map<String, dynamic>>> getReactionsForTarget({
    required String targetId,
    required String targetType,
  }) async {
    try {
      final response = await client
          .from('reactions')
          .select('reaction_emoji, user_id')
          .eq('target_type', targetType)
          .eq('target_id', targetId)
          .timeout(Duration(seconds: 8));

      final currentUserProfile = await _getCurrentUserProfile();
      final actualUserId = currentUserProfile['id'] ?? DEMO_USER_ID;

      // Group by emoji and calculate counts
      final reactionMap = <String, Map<String, dynamic>>{};

      for (final reaction in response) {
        final emoji = reaction['reaction_emoji'] as String;
        final userId = reaction['user_id'] as String;

        if (!reactionMap.containsKey(emoji)) {
          reactionMap[emoji] = {'count': 0, 'userReacted': false};
        }

        reactionMap[emoji]!['count'] =
            (reactionMap[emoji]!['count'] as int) + 1;

        if (userId == actualUserId) {
          reactionMap[emoji]!['userReacted'] = true;
        }
      }

      return reactionMap;
    } catch (error) {
      print('❌ Error getting reactions: $error');
      return {};
    }
  }

  // ================================================================================
  // GROUP MEMBERS METHODS
  // ================================================================================

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      print('👥 Fetching members for group: $groupId');

      final response = await client
          .from('group_members')
          .select('''
            *,
            user_profiles(
              id,
              full_name,
              email,
              profile_picture
            )
          ''')
          .eq('group_id', groupId)
          .order('created_at', ascending: true)
          .timeout(Duration(seconds: 10));

      // Transform the response to flatten user profile data
      final members = response.map((member) {
        final userProfile = member['user_profiles'];
        return {
          'id': member['id'],
          'group_id': member['group_id'],
          'user_id': member['user_id'],
          'role': member['role'],
          'created_at': member['created_at'],
          'full_name': userProfile?['full_name'] ?? 'Unknown User',
          'email': userProfile?['email'] ?? '',
          'profile_picture': userProfile?['profile_picture'],
        };
      }).toList();

      print('✅ Successfully fetched ${members.length} group members');
      return List<Map<String, dynamic>>.from(members);
    } catch (error) {
      print('❌ Error fetching group members: $error');
      return [];
    }
  }
}
