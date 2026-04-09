import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static data
// ─────────────────────────────────────────────────────────────────────────────

const List<String> kPronounOptions = [
  'He/Him',
  'She/Her',
  'They/Them',
  'Ze/Zir',
  'Xe/Xem',
  'Prefer not to say',
  'Custom…',
];

const List<String> kCountries = [
  'Afghanistan','Albania','Algeria','Andorra','Angola','Argentina','Armenia',
  'Australia','Austria','Azerbaijan','Bahamas','Bahrain','Bangladesh','Belarus',
  'Belgium','Bolivia','Bosnia','Brazil','Bulgaria','Cambodia','Cameroon','Canada',
  'Chile','China','Colombia','Costa Rica','Croatia','Cuba','Cyprus','Czech Republic',
  'Denmark','Dominican Republic','Ecuador','Egypt','Ethiopia','Finland','France',
  'Georgia','Germany','Ghana','Greece','Guatemala','Haiti','Honduras','Hungary',
  'Iceland','India','Indonesia','Iran','Iraq','Ireland','Israel','Italy','Jamaica',
  'Japan','Jordan','Kazakhstan','Kenya','Kuwait','Latvia','Lebanon','Libya',
  'Lithuania','Luxembourg','Malaysia','Mexico','Moldova','Morocco','Mozambique',
  'Myanmar','Nepal','Netherlands','New Zealand','Nicaragua','Nigeria','North Korea',
  'Norway','Oman','Pakistan','Palestine','Panama','Paraguay','Peru','Philippines',
  'Poland','Portugal','Qatar','Romania','Russia','Saudi Arabia','Senegal','Serbia',
  'Singapore','Slovakia','Slovenia','Somalia','South Africa','South Korea','Spain',
  'Sri Lanka','Sudan','Sweden','Switzerland','Syria','Taiwan','Thailand','Tunisia',
  'Turkey','Uganda','Ukraine','United Arab Emirates','United Kingdom',
  'United States','Uruguay','Uzbekistan','Venezuela','Vietnam','Yemen','Zimbabwe',
];

// ── 4 selected categories only ────────────────────────────────────────────────
const List<Map<String, dynamic>> kTagOptions = [
  // Adventure & Outdoors
  {'tag': 'Hiking',         'icon': Icons.terrain,           'group': 'Adventure & Outdoors'},
  {'tag': 'Cycling',        'icon': Icons.directions_bike,   'group': 'Adventure & Outdoors'},
  {'tag': 'Camping',        'icon': Icons.cabin,             'group': 'Adventure & Outdoors'},
  {'tag': 'Rock Climbing',  'icon': Icons.landscape,         'group': 'Adventure & Outdoors'},
  {'tag': 'Kayaking',       'icon': Icons.kayaking,          'group': 'Adventure & Outdoors'},
  {'tag': 'Skiing',         'icon': Icons.downhill_skiing,   'group': 'Adventure & Outdoors'},
  {'tag': 'Surfing',        'icon': Icons.surfing,           'group': 'Adventure & Outdoors'},
  {'tag': 'Bird Watching',  'icon': Icons.flutter_dash,      'group': 'Adventure & Outdoors'},
  // Sports & Fitness
  {'tag': 'Running',        'icon': Icons.directions_run,    'group': 'Sports & Fitness'},
  {'tag': 'Gym',            'icon': Icons.fitness_center,    'group': 'Sports & Fitness'},
  {'tag': 'Football',       'icon': Icons.sports_soccer,     'group': 'Sports & Fitness'},
  {'tag': 'Basketball',     'icon': Icons.sports_basketball, 'group': 'Sports & Fitness'},
  {'tag': 'Swimming',       'icon': Icons.pool,              'group': 'Sports & Fitness'},
  {'tag': 'Tennis',         'icon': Icons.sports_tennis,     'group': 'Sports & Fitness'},
  {'tag': 'Volleyball',     'icon': Icons.sports_volleyball, 'group': 'Sports & Fitness'},
  {'tag': 'Yoga',           'icon': Icons.self_improvement,  'group': 'Sports & Fitness'},
  // Food & Drink
  {'tag': 'Foodie',         'icon': Icons.restaurant,        'group': 'Food & Drink'},
  {'tag': 'Coffee',         'icon': Icons.coffee,            'group': 'Food & Drink'},
  {'tag': 'Craft Beer',     'icon': Icons.sports_bar,        'group': 'Food & Drink'},
  {'tag': 'Cooking',        'icon': Icons.kitchen,           'group': 'Food & Drink'},
  {'tag': 'Vegan',          'icon': Icons.eco,               'group': 'Food & Drink'},
  {'tag': 'Street Food',    'icon': Icons.fastfood,          'group': 'Food & Drink'},
  {'tag': 'Wine',           'icon': Icons.wine_bar,          'group': 'Food & Drink'},
  // Travel & Local
  {'tag': 'Backpacking',    'icon': Icons.luggage,           'group': 'Travel & Local'},
  {'tag': 'Road Trips',     'icon': Icons.directions_car,    'group': 'Travel & Local'},
  {'tag': 'Hidden Gems',    'icon': Icons.place,             'group': 'Travel & Local'},
  {'tag': 'Volunteering',   'icon': Icons.volunteer_activism,'group': 'Travel & Local'},
  {'tag': 'City Explorer',  'icon': Icons.location_city,     'group': 'Travel & Local'},
  {'tag': 'Night Life',     'icon': Icons.nightlife,         'group': 'Travel & Local'},
];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditProfilePage({super.key, required this.initialData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color blue    = Color(0xFF1E88E5);
  static const Color yellow  = Color(0xFFFFD600);
  static const Color white   = Color(0xFFFFFFFF);
  static const Color grey50  = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey900 = Color(0xFF212121);

  // ── Controllers ───────────────────────────────────────────────────────────
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _realNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _customPronounCtrl;

  // ── State ─────────────────────────────────────────────────────────────────
  String       _selectedPronoun  = '';
  String       _selectedCountry  = '';
  List<String> _selectedTags     = [];
  File?        _pickedImageFile;
  String       _existingPhotoUrl = '';
  bool         _isSaving         = false;

  final Set<String> _expandedGroups = {
    'Adventure & Outdoors',
    'Sports & Fitness',
  };

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _usernameCtrl      = TextEditingController(text: d['username'] ?? '');
    _realNameCtrl      = TextEditingController(text: d['realName'] ?? '');
    _bioCtrl           = TextEditingController(text: d['bio']      ?? '');
    _customPronounCtrl = TextEditingController();
    _existingPhotoUrl  = d['photoUrl'] ?? '';
    _selectedCountry   = d['country']  ?? '';

    final savedPronouns = d['pronouns'] as String? ?? '';
    if (kPronounOptions.contains(savedPronouns) || savedPronouns.isEmpty) {
      _selectedPronoun = savedPronouns;
    } else {
      _selectedPronoun = 'Custom…';
      _customPronounCtrl.text = savedPronouns;
    }

    final rawTags = d['tags'];
    if (rawTags is List) _selectedTags = List<String>.from(rawTags);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _realNameCtrl.dispose();
    _bioCtrl.dispose();
    _customPronounCtrl.dispose();
    super.dispose();
  }

  // ── Photo picker (gallery only) ───────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (picked != null) setState(() => _pickedImageFile = File(picked.path));
  }

  void _showPhotoOptions() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: blue),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            if (_existingPhotoUrl.isNotEmpty || _pickedImageFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _pickedImageFile  = null;
                    _existingPhotoUrl = '';
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    String photoUrl = _existingPhotoUrl;
    if (_pickedImageFile != null) {
      final uploaded =
      await AuthService.instance.uploadProfilePhoto(_pickedImageFile!);
      if (uploaded != null) photoUrl = uploaded;
    }

    final pronouns = _selectedPronoun == 'Custom…'
        ? _customPronounCtrl.text.trim()
        : _selectedPronoun;

    await AuthService.instance.updateUserProfile({
      'username': _usernameCtrl.text.trim(),
      'realName': _realNameCtrl.text.trim(),
      'pronouns': pronouns,
      'bio':      _bioCtrl.text.trim(),
      'country':  _selectedCountry,
      'tags':     _selectedTags,
      'photoUrl': photoUrl,
    });

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grey50,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
              color: grey900, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: grey600),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: blue),
              )
                  : const Text(
                'Save',
                style: TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: grey200),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [

          // ── Avatar ─────────────────────────────────────────────────────
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: _showPhotoOptions,
              child: Stack(
                children: [
                  _buildAvatar(),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      width: 32, height: 32,
                      decoration: const BoxDecoration(
                          color: blue, shape: BoxShape.circle),
                      child: const Icon(Icons.photo_library,
                          color: white, size: 17),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _showPhotoOptions,
              child: const Text('Change photo',
                  style: TextStyle(color: blue, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 8),

          // ── Basic info ─────────────────────────────────────────────────
          _SectionHeader(title: 'Basic Info'),
          _FieldCard(children: [
            _FormField(
              controller: _usernameCtrl,
              label: 'Username',
              icon: Icons.alternate_email,
              hint: 'e.g. ryan_adventures',
            ),
            _FieldDivider(),
            _FormField(
              controller: _realNameCtrl,
              label: 'Real Name',
              icon: Icons.person_outline,
              hint: 'Your display name',
            ),
          ]),

          // ── Pronouns ───────────────────────────────────────────────────
          _SectionHeader(title: 'Pronouns'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: grey200),
              ),
              child: _PronounSelector(
                selected: _selectedPronoun,
                customController: _customPronounCtrl,
                onChanged: (v) => setState(() => _selectedPronoun = v),
              ),
            ),
          ),

          // ── Bio ────────────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          _FieldCard(children: [
            _FormField(
              controller: _bioCtrl,
              label: 'Bio',
              icon: Icons.notes,
              hint: 'Tell the community about yourself…',
              maxLines: 4,
              maxLength: 200,
            ),
          ]),

          // ── Country ────────────────────────────────────────────────────
          _SectionHeader(title: 'Nationality'),
          _FieldCard(children: [
            InkWell(
              onTap: () => _showCountryPicker(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined,
                        color: blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCountry.isEmpty
                            ? 'Select country…'
                            : _selectedCountry,
                        style: TextStyle(
                          color: _selectedCountry.isEmpty
                              ? grey500
                              : grey900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: grey500, size: 20),
                  ],
                ),
              ),
            ),
          ]),

          // ── Tags ───────────────────────────────────────────────────────
          _SectionHeader(
            title: 'Interests & Tags',
            subtitle: '${_selectedTags.length}/10',
          ),
          _TagSelector(
            selected: _selectedTags,
            expanded: _expandedGroups,
            onToggleTag: (tag) {
              setState(() {
                if (_selectedTags.contains(tag)) {
                  _selectedTags.remove(tag);
                } else if (_selectedTags.length < 10) {
                  _selectedTags.add(tag);
                }
              });
            },
            onToggleGroup: (group) {
              setState(() {
                if (_expandedGroups.contains(group)) {
                  _expandedGroups.remove(group);
                } else {
                  _expandedGroups.add(group);
                }
              });
            },
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select up to 10 tags that describe your interests.',
              style: TextStyle(color: grey500, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(
        initial: _selectedCountry,
        onSelected: (c) => setState(() => _selectedCountry = c),
      ),
    );
  }

  Widget _buildAvatar() {
    const double size = 96;
    if (_pickedImageFile != null) {
      return CircleAvatar(
          radius: size / 2,
          backgroundImage: FileImage(_pickedImageFile!));
    }
    if (_existingPhotoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _existingPhotoUrl,
        imageBuilder: (_, img) =>
            CircleAvatar(radius: size / 2, backgroundImage: img),
        placeholder: (_, __) => _defaultAvatar(size),
        errorWidget: (_, __, ___) => _defaultAvatar(size),
      );
    }
    return _defaultAvatar(size);
  }

  Widget _defaultAvatar(double size) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(
        shape: BoxShape.circle, color: Color(0xFFEEEEEE)),
    child: const Icon(Icons.person,
        size: 52, color: Color(0xFF9E9E9E)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Country picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onSelected;
  const _CountryPickerSheet(
      {required this.initial, required this.onSelected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<String> _filtered = kCountries;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String q) => setState(() {
    _filtered = q.isEmpty
        ? kCountries
        : kCountries
        .where((c) => c.toLowerCase().contains(q.toLowerCase()))
        .toList();
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search countries…',
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF1E88E5)),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                return ListTile(
                  title: Text(c),
                  trailing: c == widget.initial
                      ? const Icon(Icons.check,
                      color: Color(0xFF1E88E5))
                      : null,
                  onTap: () {
                    widget.onSelected(c);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pronoun selector
// ─────────────────────────────────────────────────────────────────────────────

class _PronounSelector extends StatelessWidget {
  final String selected;
  final TextEditingController customController;
  final ValueChanged<String> onChanged;

  const _PronounSelector({
    required this.selected,
    required this.customController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kPronounOptions.map((p) {
            final active = p == selected;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(p);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF1E88E5)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF1E88E5)
                        : const Color(0xFFEEEEEE),
                  ),
                ),
                child: Text(
                  p,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF757575),
                    fontSize: 13,
                    fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (selected == 'Custom…') ...[
          const SizedBox(height: 12),
          TextField(
            controller: customController,
            decoration: InputDecoration(
              hintText: 'Enter your pronouns…',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF1E88E5), width: 1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag selector
// ─────────────────────────────────────────────────────────────────────────────

class _TagSelector extends StatelessWidget {
  final List<String> selected;
  final Set<String> expanded;
  final ValueChanged<String> onToggleTag;
  final ValueChanged<String> onToggleGroup;

  const _TagSelector({
    required this.selected,
    required this.expanded,
    required this.onToggleTag,
    required this.onToggleGroup,
  });

  @override
  Widget build(BuildContext context) {
    // Build ordered group map
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final t in kTagOptions) {
      final g = t['group'] as String;
      groups.putIfAbsent(g, () => []).add(t);
    }

    return Column(
      children: groups.entries.map((entry) {
        final groupName = entry.key;
        final tags      = entry.value;
        final isOpen    = expanded.contains(groupName);
        final selCount  = tags
            .where((t) => selected.contains(t['tag']))
            .length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                // Header
                InkWell(
                  borderRadius: isOpen
                      ? const BorderRadius.vertical(
                      top: Radius.circular(14))
                      : BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggleGroup(groupName);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    child: Row(
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(
                            color: Color(0xFF212121),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (selCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$selCount',
                              style: const TextStyle(
                                color: Color(0xFF1E88E5),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Icon(
                          isOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ],
                    ),
                  ),
                ),
                // Chips
                if (isOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((t) {
                        final tagName = t['tag'] as String;
                        final icon    = t['icon'] as IconData;
                        final active  = selected.contains(tagName);
                        final maxed   = selected.length >= 10 && !active;

                        return GestureDetector(
                          onTap: maxed
                              ? () => HapticFeedback.vibrate()
                              : () {
                            HapticFeedback.selectionClick();
                            onToggleTag(tagName);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFF1E88E5)
                                  : maxed
                                  ? const Color(0xFFF5F5F5)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? const Color(0xFF1E88E5)
                                    : const Color(0xFFEEEEEE),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon,
                                    size: 14,
                                    color: active
                                        ? Colors.white
                                        : maxed
                                        ? const Color(0xFFBDBDBD)
                                        : const Color(0xFF757575)),
                                const SizedBox(width: 5),
                                Text(
                                  tagName,
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : maxed
                                        ? const Color(0xFFBDBDBD)
                                        : const Color(0xFF757575),
                                    fontSize: 13,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF1E88E5),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const Spacer(),
            Text(subtitle!,
                style: const TextStyle(
                    color: Color(0xFF9E9E9E), fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final List<Widget> children;
  const _FieldCard({required this.children});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(children: children),
    ),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final int maxLines;
  final int? maxLength;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.maxLines  = 1,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 2 : 0),
            child:
            Icon(icon, color: const Color(0xFF1E88E5), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines:   maxLines,
              maxLength:  maxLength,
              style: const TextStyle(
                  color: Color(0xFF212121), fontSize: 15),
              decoration: InputDecoration(
                labelText: label,
                hintText:  hint,
                hintStyle: const TextStyle(
                    color: Color(0xFF9E9E9E), fontSize: 14),
                border:    InputBorder.none,
                isDense:   true,
                counterStyle:
                const TextStyle(color: Color(0xFF9E9E9E)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.only(left: 48),
    color: const Color(0xFFEEEEEE),
  );
}