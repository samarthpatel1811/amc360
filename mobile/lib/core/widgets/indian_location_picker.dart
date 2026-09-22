import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Comprehensive Indian States & UTs with their respective cities
const Map<String, List<String>> kIndianStatesAndCities = {
  'Andhra Pradesh': [
    'Anantapur', 'Chittoor', 'Eluru', 'Guntur', 'Kadapa', 'Kakinada',
    'Kurnool', 'Machilipatnam', 'Nandyal', 'Nellore', 'Ongole',
    'Rajahmundry', 'Srikakulam', 'Tirupati', 'Vijayawada', 'Visakhapatnam', 'Vizianagaram'
  ],
  'Arunachal Pradesh': [
    'Itanagar', 'Naharlagun', 'Pasighat', 'Tawang', 'Ziro', 'Bomdila'
  ],
  'Assam': [
    'Barpeta', 'Bongaigaon', 'Dibrugarh', 'Guwahati', 'Jorhat', 'Nagaon',
    'Silchar', 'Tezpur', 'Tinsukia'
  ],
  'Bihar': [
    'Arrah', 'Begusarai', 'Bhagalpur', 'Bihar Sharif', 'Chhapra', 'Darbhanga',
    'Gaya', 'Hajipur', 'Katihar', 'Madhubani', 'Motihari', 'Munger',
    'Muzaffarpur', 'Nawada', 'Patna', 'Purnia', 'Saharsa', 'Sasaram', 'Siwan'
  ],
  'Chandigarh': [
    'Chandigarh'
  ],
  'Chhattisgarh': [
    'Ambikapur', 'Bhilai', 'Bilaspur', 'Dhamtari', 'Durg', 'Jagdalpur',
    'Korba', 'Raigarh', 'Raipur', 'Rajnandgaon'
  ],
  'Dadra and Nagar Haveli and Daman and Diu': [
    'Daman', 'Diu', 'Silvassa'
  ],
  'Delhi (NCR)': [
    'Central Delhi', 'Connaught Place', 'Dwarka', 'East Delhi', 'Faridabad',
    'Ghaziabad', 'Greater Noida', 'Gurugram', 'Karol Bagh', 'Lajpat Nagar',
    'New Delhi', 'Noida', 'North Delhi', 'Rohini', 'Saket', 'South Delhi', 'West Delhi'
  ],
  'Goa': [
    'Bicholim', 'Canacona', 'Curchorem', 'Mapusa', 'Margao', 'Mormugao',
    'Panaji', 'Ponda', 'Vasco da Gama'
  ],
  'Gujarat': [
    'Ahmedabad', 'Amreli', 'Anand', 'Ankleshwar', 'Bardoli', 'Bharuch',
    'Bhavnagar', 'Bhuj', 'Botad', 'Dahod', 'Deesa', 'Gandhidham',
    'Gandhinagar', 'Godhra', 'Gondal', 'Himatnagar', 'Jamnagar', 'Jetpur',
    'Junagadh', 'Kadi', 'Kalol', 'Keshod', 'Khambhat', 'Mehsana',
    'Modasa', 'Morbi', 'Nadiad', 'Navsari', 'Palanpur', 'Patan',
    'Porbandar', 'Rajkot', 'Sanand', 'Surendranagar', 'Surat', 'Unjha',
    'Vadodara', 'Valsad', 'Vapi', 'Veraval'
  ],
  'Haryana': [
    'Ambala', 'Bahadurgarh', 'Bhiwani', 'Faridabad', 'Gurugram', 'Hisar',
    'Jind', 'Kaithal', 'Karnal', 'Kurukshetra', 'Palwal', 'Panchkula',
    'Panipat', 'Rewari', 'Rohtak', 'Sirsa', 'Sonipat', 'Yamunanagar'
  ],
  'Himachal Pradesh': [
    'Baddi', 'Bilaspur', 'Chamba', 'Dharamshala', 'Hamirpur', 'Kullu',
    'Mandi', 'Nahan', 'Paonta Sahib', 'Shimla', 'Solan', 'Una'
  ],
  'Jammu & Kashmir': [
    'Anantnag', 'Baramulla', 'Jammu', 'Kathua', 'Pulwama', 'Sopore',
    'Srinagar', 'Udhampur'
  ],
  'Jharkhand': [
    'Bokaro Steel City', 'Chaibasa', 'Deoghar', 'Dhanbad', 'Giridih',
    'Hazaribagh', 'Jamshedpur', 'Phusro', 'Ramgarh', 'Ranchi'
  ],
  'Karnataka': [
    'Ballari', 'Belagavi', 'Bengaluru', 'Bidar', 'Chikkamagaluru',
    'Davanagere', 'Gadag', 'Hassan', 'Hosapete', 'Hubballi-Dharwad',
    'Kalaburagi', 'Kolar', 'Mandya', 'Mangaluru', 'Mysuru', 'Raichur',
    'Shivamogga', 'Tumakuru', 'Udupi', 'Vijayapura'
  ],
  'Kerala': [
    'Alappuzha', 'Ernakulam', 'Kannur', 'Kasaragod', 'Kochi', 'Kollam',
    'Kottayam', 'Kozhikode', 'Malappuram', 'Manjeri', 'Palakkad',
    'Thalassery', 'Thiruvananthapuram', 'Thrissur'
  ],
  'Ladakh': [
    'Kargil', 'Leh'
  ],
  'Madhya Pradesh': [
    'Bhind', 'Bhopal', 'Burhanpur', 'Chhindwara', 'Dewas', 'Guna',
    'Gwalior', 'Hoshangabad', 'Indore', 'Jabalpur', 'Katni', 'Khandwa',
    'Morena', 'Nagda', 'Ratlam', 'Rewa', 'Sagar', 'Satna', 'Shivpuri',
    'Singrauli', 'Ujjain', 'Vidisha'
  ],
  'Maharashtra': [
    'Ahmednagar', 'Akola', 'Amravati', 'Aurangabad (Chh. Sambhajinagar)',
    'Baramati', 'Beed', 'Bhandara', 'Bhiwandi', 'Bhusawal', 'Chandrapur',
    'Dhule', 'Gondia', 'Ichalkaranji', 'Jalgaon', 'Jalna', 'Kalyan-Dombivli',
    'Kolhapur', 'Latur', 'Malegaon', 'Mira-Bhayandar', 'Mumbai',
    'Nagpur', 'Nanded', 'Nandurbar', 'Nashik', 'Navi Mumbai', 'Osmanabad',
    'Palghar', 'Panvel', 'Parbhani', 'Pimpri-Chinchwad', 'Pune',
    'Ratnagiri', 'Sangli', 'Satara', 'Solapur', 'Thane', 'Ulhasnagar',
    'Vasai-Virar', 'Wardha', 'Yavatmal'
  ],
  'Manipur': [
    'Churachandpur', 'Imphal', 'Thoubal', 'Ukhrul'
  ],
  'Meghalaya': [
    'Cherrapunji', 'Jowai', 'Nongpoh', 'Shillong', 'Tura'
  ],
  'Mizoram': [
    'Aizawl', 'Champhai', 'Kolasib', 'Lunglei', 'Serchhip'
  ],
  'Nagaland': [
    'Dimapur', 'Kohima', 'Mokokchung', 'Tuensang', 'Wokha'
  ],
  'Odisha': [
    'Balangir', 'Balasore', 'Bhadrak', 'Bhubaneswar', 'Brahmapur',
    'Cuttack', 'Jharsuguda', 'Puri', 'Rourkela', 'Sambalpur'
  ],
  'Puducherry': [
    'Karaikal', 'Mahe', 'Puducherry', 'Yanam'
  ],
  'Punjab': [
    'Abohar', 'Amritsar', 'Barnala', 'Bathinda', 'Faridkot', 'Firozpur',
    'Hoshiarpur', 'Jalandhar', 'Kapurthala', 'Khanna', 'Ludhiana',
    'Malerkotla', 'Moga', 'Mohali (SAS Nagar)', 'Muktsar', 'Pathankot',
    'Patiala', 'Phagwara', 'Rajpura'
  ],
  'Rajasthan': [
    'Ajmer', 'Alwar', 'Barmer', 'Beawar', 'Bharatpur', 'Bhilwara',
    'Bikaner', 'Chittorgarh', 'Churu', 'Hanumangarh', 'Hindaun',
    'Jaipur', 'Jaisalmer', 'Jhunjhunu', 'Jodhpur', 'Kishangarh',
    'Kota', 'Nagaur', 'Pali', 'Sawai Madhopur', 'Sikar',
    'Sri Ganganagar', 'Tonk', 'Udaipur'
  ],
  'Sikkim': [
    'Gangtok', 'Gyalshing', 'Mangan', 'Namchi'
  ],
  'Tamil Nadu': [
    'Chennai', 'Coimbatore', 'Cuddalore', 'Dindigul', 'Erode',
    'Hosur', 'Kanchipuram', 'Karaikudi', 'Karur', 'Kumbakonam',
    'Madurai', 'Nagercoil', 'Neyveli', 'Ooty', 'Pudukkottai',
    'Ranipet', 'Salem', 'Sivakasi', 'Thanjavur', 'Theni',
    'Thoothukudi', 'Tiruchirappalli', 'Tirunelveli', 'Tiruppur',
    'Tiruvannamalai', 'Vellore', 'Viluppuram'
  ],
  'Telangana': [
    'Adilabad', 'Hyderabad', 'Jagtial', 'Karimnagar', 'Khammam',
    'Mahbubnagar', 'Mancherial', 'Miryalaguda', 'Nalgonda', 'Nizamabad',
    'Ramagundam', 'Secunderabad', 'Siddipet', 'Suryapet', 'Warangal'
  ],
  'Tripura': [
    'Agartala', 'Dharmanagar', 'Kailashahar', 'Udaipur'
  ],
  'Uttar Pradesh': [
    'Agra', 'Aligarh', 'Amroha', 'Ayodhya', 'Azamgarh', 'Bahraich',
    'Ballia', 'Banda', 'Bareilly', 'Basti', 'Budaun', 'Bulandshahr',
    'Etawah', 'Farrukhabad', 'Fatehpur', 'Firozabad', 'Ghaziabad',
    'Gonda', 'Gorakhpur', 'Hapur', 'Hardoi', 'Hathras', 'Jaunpur',
    'Jhansi', 'Kanpur', 'Lakhimpur', 'Lucknow', 'Mathura', 'Mau',
    'Meerut', 'Mirzapur', 'Moradabad', 'Muzaffarnagar', 'Noida',
    'Orai', 'Pilibhit', 'Prayagraj (Allahabad)', 'Rae Bareli',
    'Rampur', 'Saharanpur', 'Sambhal', 'Shahjahanpur', 'Sitapur',
    'Sultanpur', 'Unnao', 'Varanasi'
  ],
  'Uttarakhand': [
    'Dehradun', 'Haldwani', 'Haridwar', 'Kashipur', 'Kotdwar',
    'Mussoorie', 'Nainital', 'Rishikesh', 'Roorkee', 'Rudrapur'
  ],
  'West Bengal': [
    'Asansol', 'Baharampur', 'Bankura', 'Bardhaman', 'Cooch Behar',
    'Darjeeling', 'Durgapur', 'Haldia', 'Howrah', 'Jalpaiguri',
    'Kalyani', 'Kharagpur', 'Kolkata', 'Malda', 'Midnapore',
    'Purulia', 'Raiganj', 'Siliguri'
  ],
};

/// Interactive state & city selector widget
class StateCitySelector extends StatefulWidget {
  final String? initialValueState;
  final String? initialValueCity;
  final Function(String state, String city) onChanged;
  final bool isRequired;

  const StateCitySelector({
    super.key,
    this.initialValueState,
    this.initialValueCity,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  State<StateCitySelector> createState() => _StateCitySelectorState();
}

class _StateCitySelectorState extends State<StateCitySelector> {
  String? _selectedState;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _selectedState = widget.initialValueState;
    _selectedCity = widget.initialValueCity;
  }

  @override
  void didUpdateWidget(covariant StateCitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValueState != oldWidget.initialValueState && widget.initialValueState != null) {
      _selectedState = widget.initialValueState;
    }
    if (widget.initialValueCity != oldWidget.initialValueCity && widget.initialValueCity != null) {
      _selectedCity = widget.initialValueCity;
    }
  }

  Future<void> _openStatePicker(BuildContext context, bool isDark) async {
    final states = kIndianStatesAndCities.keys.toList()..sort();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _SearchablePickerSheet(
        title: 'Select Indian State / UT',
        searchHint: 'Search state (e.g. Gujarat, Maharashtra)...',
        items: states,
        selectedItem: _selectedState,
        isDark: isDark,
      ),
    );

    if (result != null && result != _selectedState) {
      setState(() {
        _selectedState = result;
        // Check if existing city belongs to new state, if not clear it
        final availableCities = kIndianStatesAndCities[result] ?? [];
        if (_selectedCity != null && !availableCities.contains(_selectedCity)) {
          _selectedCity = null;
        }
      });
      widget.onChanged(_selectedState ?? '', _selectedCity ?? '');
    }
  }

  Future<void> _openCityPicker(BuildContext context, bool isDark) async {
    if (_selectedState == null || _selectedState!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a state first to view its cities.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final cities = (kIndianStatesAndCities[_selectedState] ?? []).toList()..sort();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _SearchablePickerSheet(
        title: 'Select City ($_selectedState)',
        searchHint: 'Search city in $_selectedState (e.g. Ahmedabad)...',
        items: cities,
        selectedItem: _selectedCity,
        isDark: isDark,
        allowCustomEntry: true,
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedCity = result;
      });
      widget.onChanged(_selectedState ?? '', _selectedCity ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // State Picker Field
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'State / UT${widget.isRequired ? ' *' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _openStatePicker(context, isDark),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: _selectedState != null
                            ? const Color(0xFF2563EB)
                            : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedState ?? 'Select State',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: _selectedState != null ? FontWeight.w600 : FontWeight.normal,
                            color: _selectedState != null
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // City Picker Field
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'City${widget.isRequired ? ' *' : ''}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _openCityPicker(context, isDark),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _selectedState == null
                        ? (isDark ? Colors.white.withAlpha(5) : const Color(0xFFF1F5F9))
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_city_rounded,
                        size: 18,
                        color: _selectedCity != null
                            ? const Color(0xFF0D9488)
                            : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedState == null
                              ? 'Pick state first'
                              : (_selectedCity ?? 'Select City'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: _selectedCity != null ? FontWeight.w600 : FontWeight.normal,
                            color: _selectedCity != null
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Searchable modal bottom sheet with top search input and smooth scrolling list
class _SearchablePickerSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final List<String> items;
  final String? selectedItem;
  final bool isDark;
  final bool allowCustomEntry;

  const _SearchablePickerSheet({
    required this.title,
    required this.searchHint,
    required this.items,
    this.selectedItem,
    required this.isDark,
    this.allowCustomEntry = false,
  });

  @override
  State<_SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<_SearchablePickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((i) => i.toLowerCase().contains(q)).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final queryText = _searchCtrl.text.trim();

    return Container(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: false,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Scrollable List of Cities / States
            Flexible(
              child: _filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No matching results found',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          if (widget.allowCustomEntry && queryText.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context, queryText),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: Text('Use "$queryText"'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredItems.length + (widget.allowCustomEntry && queryText.isNotEmpty && !_filteredItems.contains(queryText) ? 1 : 0),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      itemBuilder: (context, index) {
                        if (index == _filteredItems.length) {
                          // Custom entry tile
                          return ListTile(
                            leading: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2563EB)),
                            title: Text(
                              'Use custom: "$queryText"',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                            ),
                            onTap: () => Navigator.pop(context, queryText),
                          );
                        }

                        final item = _filteredItems[index];
                        final isSelected = item == widget.selectedItem;

                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          tileColor: isSelected
                              ? const Color(0xFF2563EB).withAlpha(isDark ? 40 : 20)
                              : null,
                          title: Text(
                            item,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 18)
                              : null,
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
