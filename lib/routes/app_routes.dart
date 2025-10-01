import 'package:flutter/material.dart';
import '../presentation/home_dashboard_screen/home_dashboard_screen.dart';
import '../presentation/group_dashboard_screen/group_dashboard_screen.dart';
import '../presentation/event_details_screen/event_details_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/group_creation_screen/group_creation_screen.dart';
import '../presentation/expense_creation_screen/expense_creation_screen.dart';
import '../presentation/notes_and_polls_screen/notes_and_polls_screen.dart';
import '../presentation/event_creation_screen/event_creation_screen.dart';
import '../presentation/member_invitation_screen/member_invitation_screen.dart';
import '../presentation/phone_authentication_screen/phone_authentication_screen.dart';
import '../presentation/groups_list_screen/groups_list_screen.dart';
import '../presentation/profile_setup_screen/profile_setup_screen.dart';
import '../presentation/otp_verification_screen/otp_verification_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String homeDashboard = '/home-dashboard-screen';
  static const String groupDashboard = '/group-dashboard-screen';
  static const String eventDetails = '/event-details-screen';
  static const String splash = '/splash-screen';
  static const String groupCreation = '/group-creation-screen';
  static const String expenseCreation = '/expense-creation-screen';
  static const String notesAndPolls = '/notes-and-polls-screen';
  static const String eventCreation = '/event-creation-screen';
  static const String memberInvitation = '/member-invitation-screen';
  static const String phoneAuthentication = '/phone-authentication-screen';
  static const String groupsList = '/groups-list-screen';
  static const String profileSetup = '/profile-setup-screen';
  static const String otpVerification = '/otp-verification-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const PhoneAuthenticationScreen(),
    homeDashboard: (context) => const HomeDashboardScreen(),
    groupDashboard: (context) => const GroupDashboardScreen(),
    eventDetails: (context) => const EventDetailsScreen(),
    splash: (context) => const SplashScreen(),
    groupCreation: (context) => const GroupCreationScreen(),
    expenseCreation: (context) => const ExpenseCreationScreen(),
    notesAndPolls: (context) => const NotesAndPollsScreen(),
    eventCreation: (context) => const EventCreationScreen(),
    memberInvitation: (context) => const MemberInvitationScreen(),
    phoneAuthentication: (context) => const PhoneAuthenticationScreen(),
    groupsList: (context) => const GroupsListScreen(),
    profileSetup: (context) => const ProfileSetupScreen(),
    otpVerification: (context) => const OtpVerificationScreen(),
    // TODO: Add your other routes here
  };
}
