import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/features/profile/providers/profile_provider.dart';
import 'package:meal_app/features/profile/data/models/profile_models.dart';
import 'package:meal_app/core/utils/error_handler.dart';
import 'package:meal_app/core/providers/lookup_provider.dart';
import 'package:meal_app/core/widgets/searchable_dropdown.dart';
import 'package:meal_app/core/models/lookup_models.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _schoolController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  
  SchoolModel? _selectedSchool;
  StateModel? _selectedState;
  CityModel? _selectedCity;
  
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _schoolController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ProfileProvider>();
      final lookupProvider = context.read<LookupProvider>();
      await provider.fetchProfiles(force: true);
      final profile = provider.teacherProfile;
      if (profile != null && mounted) {
        // Fetch lookup data to prefill the dropdowns
        await lookupProvider.fetchInitialData();

        // Find existing selections
        _selectedSchool = lookupProvider.schools.where((s) => s.name == profile.schoolCollegeName).firstOrNull;
        _selectedState = lookupProvider.states.where((s) => s.name == profile.state).firstOrNull;
        _selectedCity = lookupProvider.cities.where((s) => s.name == profile.city).firstOrNull;

        setState(() {
          _nameController.text = profile.name;
          _schoolController.text = profile.schoolCollegeName;
          _cityController.text = profile.city;
          _stateController.text = profile.state;
          _status = profile.status;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final lookupProvider = context.watch<LookupProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: profileProvider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Update your teacher profile details below.',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(CupertinoIcons.person_fill),
                    ),
                    validator: (v) => v!.isEmpty ? 'Full Name is required' : null,
                  ),
                  const SizedBox(height: 20),
                  SearchableDropdown<SchoolModel>(
                    label: 'School/College Name',
                    items: lookupProvider.schools,
                    itemLabel: (s) => s.name,
                    value: _selectedSchool,
                    isLoading: lookupProvider.isLoading,
                    listenable: lookupProvider,
                    itemsGetter: () => lookupProvider.schools,
                    loadingGetter: () => lookupProvider.isLoading,
                    validator: (v) => v == null ? 'School/College is required' : null,
                    onInteraction: () {
                      FocusScope.of(context).unfocus();
                      lookupProvider.fetchInitialData();
                    },
                    onChanged: (v) {
                      setState(() {
                        _selectedSchool = v;
                        _schoolController.text = v?.name ?? '';
                      });
                    },
                  ),
                  SearchableDropdown<CityModel>(
                    label: 'City',
                    items: lookupProvider.cities,
                    itemLabel: (s) => s.name,
                    value: _selectedCity,
                    isLoading: lookupProvider.isLoading,
                    listenable: lookupProvider,
                    itemsGetter: () => lookupProvider.cities,
                    loadingGetter: () => lookupProvider.isLoading,
                    validator: (v) => v == null ? 'City is required' : null,
                    onInteraction: () {
                      FocusScope.of(context).unfocus();
                      lookupProvider.fetchInitialData();
                    },
                    onChanged: (v) {
                      setState(() {
                        _selectedCity = v;
                        _cityController.text = v?.name ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SearchableDropdown<StateModel>(
                    label: 'State',
                    items: lookupProvider.states,
                    itemLabel: (s) => s.name,
                    value: _selectedState,
                    isLoading: lookupProvider.isLoading,
                    listenable: lookupProvider,
                    itemsGetter: () => lookupProvider.states,
                    loadingGetter: () => lookupProvider.isLoading,
                    validator: (v) => v == null ? 'State is required' : null,
                    onInteraction: () {
                      FocusScope.of(context).unfocus();
                      lookupProvider.fetchInitialData();
                    },
                    onChanged: (v) {
                      setState(() {
                        _selectedState = v;
                        _stateController.text = v?.name ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final profile = TeacherProfileModel(
                          name: _nameController.text,
                          schoolCollegeName: _schoolController.text,
                          city: _cityController.text,
                          state: _stateController.text,
                          location: '', // Location removed as per request
                          status: _status,
                        );
                        
                        final success = await profileProvider.saveTeacherProfile(profile);
                        if (success && mounted) {
                          ErrorHandler.showSuccess(context, 'Teacher profile saved successfully');
                          Navigator.pop(context);
                        } else if (mounted) {
                          ErrorHandler.showError(context, profileProvider.error);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                    ),
                   child: const Text('Save Profile'),
                  ),
                  if (context.read<ProfileProvider>().teacherProfile != null) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _confirmDelete(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Delete Teacher Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Teacher Profile'),
        content: const Text('Are you sure you want to delete your teacher profile? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ProfileProvider>().deleteTeacherProfile();
              if (success && mounted) {
                ErrorHandler.showSuccess(context, 'Teacher profile deleted successfully');
                Navigator.pop(context);
              } else if (mounted) {
                ErrorHandler.showError(context, 'Failed to delete teacher profile');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
