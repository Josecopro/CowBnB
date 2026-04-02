import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/onboarding_page.dart';
import 'pages/registration_page.dart';
import 'pages/dashboard_renter_page.dart';
import 'pages/dashboard_owner_page.dart';
import 'pages/map_discovery_page.dart';
import 'pages/listing_details_page.dart';
import 'pages/checkout_page.dart';
import 'pages/create_listing_page.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationPage(),
    ),
    GoRoute(
      path: '/renter',
      builder: (context, state) => const DashboardRenterPage(),
    ),
    GoRoute(
      path: '/owner',
      builder: (context, state) => const DashboardOwnerPage(),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const MapDiscoveryPage(),
    ),
    GoRoute(
      path: '/listing',
      builder: (context, state) => const ListingDetailsPage(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutPage(),
    ),
    GoRoute(
      path: '/create-listing',
      builder: (context, state) => const CreateListingPage(),
    ),
  ],
);
