import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:meal_app/core/theme/app_theme.dart';
import 'package:meal_app/features/profile/providers/profile_provider.dart';
import 'package:meal_app/features/profile/data/models/profile_models.dart';
import 'package:meal_app/core/utils/error_handler.dart';
import 'package:meal_app/core/utils/validators.dart';
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
  bool _isInitializing = true;
  bool _isSaving = false;

  // Switch to onUserInteraction after first submit attempt
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

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
      
      // Fetch lookup data first so dropdowns are ready
      await lookupProvider.fetchInitialData();
      await provider.fetchProfiles(force: true);
      
      final profile = provider.teacherProfile;
      if (profile != null && mounted) {
        // Match existing selections from lookup data
        _selectedSchool = lookupProvider.schools.where((s) => s.name == profile.schoolCollegeName).firstOrNull;
        _selectedState = lookupProvider.states.where((s) => s.name.toLowerCase() == profile.state.toLowerCase()).firstOrNull;

        // Trigger dependent fetches if values exist
        if (_selectedState != null) {
          await lookupProvider.fetchCitiesByState(_selectedState!.id);
          if (mounted) {
            _selectedCity = lookupProvider.cities.where((s) => s.name.toLowerCase() == profile.city.toLowerCase()).firstOrNull;
          }
        }

        if (mounted) {
          setState(() {
            _nameController.text = profile.name;
            _schoolController.text = profile.schoolCollegeName;
            _cityController.text = profile.city;
            _stateController.text = profile.state;
            _status = profile.status;
            _isInitializing = false;
          });
        }
      } else if (mounted) {
        setState(() => _isInitializing = false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final profileProvider = context.read<ProfileProvider>();

    // Activate auto-validation so errors clear on user interaction
    if (_autovalidateMode != AutovalidateMode.onUserInteraction) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    }

    if (!_formKey.currentState!.validate()) {
      return; // errors are shown inline by validators
    }

    setState(() => _isSaving = true);

    final profile = TeacherProfileModel(
      name: _nameController.text.trim(),
      schoolCollegeName: _schoolController.text,
      city: _cityController.text,
      state: _stateController.text,
      location: '',
      status: _status,
    );
    
    final success = await profileProvider.saveTeacherProfile(profile);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ErrorHandler.showSuccess(context, 'Teacher profile saved successfully');
      Navigator.pop(context);
    } else {
      ErrorHandler.showError(context, profileProvider.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final lookupProvider = context.watch<LookupProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Teacher Profile',
          style: TextStyle(color: isDark ? Colors.white : AppTheme.textPrimaryLight),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: (profileProvider.isLoading || _isInitializing)
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: _autovalidateMode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Update your teacher profile details below.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 1. Full Name
                  TextFormField(
                    controller: _nameController,
                    autofocus: false,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(CupertinoIcons.person_fill),
                    ),
                    textInputAction: TextInputAction.done,
                    validator: (v) => Validators.name(v, fieldName: 'Full Name'),
                  ),
                  const SizedBox(height: 20),

                  // 2. School/College — ALL active schools from GET /api/client/schools
                  SearchableDropdown<SchoolModel>(
                    label: 'School/College Name',
                    items: lookupProvider.schools,
                    itemLabel: (s) => '${s.name} (${s.city})',
                    value: _selectedSchool,
                    isLoading: lookupProvider.isLoading,
                    listenable: lookupProvider,
                    itemsGetter: () => lookupProvider.schools,
                    loadingGetter: () => lookupProvider.isLoading,
                    validator: (v) => Validators.requiredField(v, 'School/College'),
                    onInteraction: () {
                      FocusScope.of(context).unfocus();
                      lookupProvider.fetchInitialData();
                    },
                    onChanged: (v) {
                      setState(() {
                        _selectedSchool = v;
                        _schoolController.text = v?.name ?? '';
                        // Auto-fill state and city from school data
                        if (v != null) {
                          _selectedState = lookupProvider.states.where((s) => s.name.toLowerCase() == v.state.toLowerCase()).firstOrNull;
                          _stateController.text = v.state;
                          if (_selectedState != null) {
                            lookupProvider.fetchCitiesByState(_selectedState!.id).then((_) {
                              if (mounted) {
                                setState(() {
                                  _selectedCity = lookupProvider.cities.where((c) => c.name.toLowerCase() == v.city.toLowerCase()).firstOrNull;
                                  _cityController.text = v.city;
                                });
                              }
                            });
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. State (auto-filled from school, but can be manually changed)
                  SearchableDropdown<StateModel>(
                    label: 'State',
                    items: lookupProvider.states,
                    itemLabel: (s) => s.name,
                    value: _selectedState,
                    isLoading: lookupProvider.isLoading,
                    listenable: lookupProvider,
                    itemsGetter: () => lookupProvider.states,
                    loadingGetter: () => lookupProvider.isLoading,
                    validator: (v) => Validators.requiredField(v, 'State'),
                    onInteraction: () {
                      FocusScope.of(context).unfocus();
                      lookupProvider.fetchInitialData();
                    },
                    onChanged: (v) {
                      setState(() {
                        if (_selectedState?.id != v?.id) {
                          _selectedState = v;
                          _stateController.text = v?.name ?? '';
                          _selectedCity = null;
                          _cityController.text = '';
                          if (v != null) {
                            lookupProvider.fetchCitiesByState(v.id);
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 4. City
                  SearchableDropdown<CityModel>(
                    label: 'City',
                    items: lookupProvider.cities,
                    itemLabel: (s) => s.name,
                    value: _selectedCity,
                    isLoading: lookupProvider.isLoading,
                    listenable: lookupProvider,
                    itemsGetter: () => lookupProvider.cities,
                    loadingGetter: () => lookupProvider.isLoading,
                    validator: (v) => Validators.requiredField(v, 'City'),
                    onInteraction: () {
                      FocusScope.of(context).unfocus();
                      if (_selectedState == null) {
                        ErrorHandler.showError(context, 'Please select a state first');
                        return;
                      }
                    },
                    onChanged: (v) {
                      setState(() {
                        _selectedCity = v;
                        _cityController.text = v?.name ?? '';
                      });
                    },
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Save Profile'),
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
                ErrorHandler.showError(context, 'Failed to delete — profile may have active subscriptions');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
