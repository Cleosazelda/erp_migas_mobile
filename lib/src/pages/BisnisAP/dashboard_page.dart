import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BisnisApDashboardPage extends StatefulWidget {
  const BisnisApDashboardPage({super.key});

  @override
  State<BisnisApDashboardPage> createState() => _BisnisApDashboardPageState();
}

class _BisnisApDashboardPageState extends State<BisnisApDashboardPage> {
  final _numberFormatter = NumberFormat.decimalPattern('id');

  final List<String> _years = ['2025', '2024', '2023', '2022', '2021', '2020'];

  String _selectedYear = '2025';
  String _selectedFilter = 'All';
  String _selectedFilterOption = 'All';

  final List<_CompanyMetrics> _companies = [
    _CompanyMetrics(
      name: 'PT MUJ ENERGI INDONESIA',
      metrics: [
        _MetricCardData(
          title: 'Pendapatan (Rp)',
          rka: 198281786454,
          realisasi: 61692946484,
          percentage: 31.11,
          gradient: [const Color(0xFFD76DFF), const Color(0xFF6A7DFF)],
          icon: Icons.signal_cellular_alt,
        ),
        _MetricCardData(
          title: 'HPP (Rp)',
          rka: 179149434544,
          realisasi: 52442801814,
          percentage: 29.27,
          gradient: [const Color(0xFFFF9F7B), const Color(0xFFFF6B6B)],
          icon: Icons.settings,
        ),
        _MetricCardData(
          title: 'Laba Kotor',
          rka: 19132351910,
          realisasi: 9250144670,
          percentage: 48.35,
          gradient: [const Color(0xFF8293A7), const Color(0xFF556372)],
          icon: Icons.attach_money,
        ),
      ],
    ),
    _CompanyMetrics(
      name: 'PT ENERGI NEGERI MANDIRI',
      metrics: [
        _MetricCardData(
          title: 'Pendapatan (Rp)',
          rka: 132274033394,
          realisasi: 9987392101,
          percentage: 7.55,
          gradient: [const Color(0xFFD76DFF), const Color(0xFF6A7DFF)],
          icon: Icons.signal_cellular_alt,
        ),
        _MetricCardData(
          title: 'HPP (Rp)',
          rka: 113930352602,
          realisasi: 24319126882,
          percentage: 21.35,
          gradient: [const Color(0xFFFF9F7B), const Color(0xFFFF6B6B)],
          icon: Icons.settings,
        ),
        _MetricCardData(
          title: 'Laba Kotor (Rp)',
          rka: 18343680792,
          realisasi: -14331734781,
          percentage: -78.13,
          gradient: [const Color(0xFF8293A7), const Color(0xFF556372)],
          icon: Icons.attach_money,
        ),
      ],
    ),
    _CompanyMetrics(
      name: 'PT MIGAS UTAMA JABAR ONWJ',
      metrics: [
        _MetricCardData(
          title: 'Pendapatan (Rp)',
          rka: 1087088656000,
          realisasi: 301377298289,
          percentage: 27.72,
          gradient: [const Color(0xFFD76DFF), const Color(0xFF6A7DFF)],
          icon: Icons.signal_cellular_alt,
        ),
        _MetricCardData(
          title: 'HPP (Rp)',
          rka: 923287392000,
          realisasi: 269870318886,
          percentage: 29.23,
          gradient: [const Color(0xFFFF9F7B), const Color(0xFFFF6B6B)],
          icon: Icons.settings,
        ),
        _MetricCardData(
          title: 'Laba Kotor (Rp)',
          rka: 163801264000,
          realisasi: 31506979403,
          percentage: 19.23,
          gradient: [const Color(0xFF8293A7), const Color(0xFF556372)],
          icon: Icons.attach_money,
        ),
      ],
    ),
  ];

  List<String> get _availableFilters => _selectedYear == '2025'
      ? ['All', 'Semester', 'Triwulan']
      : ['All'];

  List<String> get _availableFilterOptions {
    if (_selectedFilter == 'Semester') return ['1', '2'];
    if (_selectedFilter == 'Triwulan') return ['1', '2', '3', '4'];
    return ['All'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? colorScheme.surface : Colors.white;
    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Builder(builder: (context) => _buildAppBar(theme, colorScheme, surfaceColor)),
      ),

      drawer: _buildDrawer(context, surfaceColor: surfaceColor, isDark: isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilters(theme),
              const SizedBox(height: 24),
              ..._companies.map(_buildCompanySection),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme, ColorScheme colorScheme, Color surfaceColor) {
    return AppBar(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.menu, color: colorScheme.onSurface),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('assets/images/logo.png'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bisnis Anak Perusahaan',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Dashboard Bisnis AP',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, {required Color surfaceColor, required bool isDark}) {
    final theme = Theme.of(context);
    return Drawer(
      child: Container(
        color: surfaceColor,
        child: Column(
          children: [
            _buildDrawerHeader(theme, surfaceColor: surfaceColor, isDark: isDark),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionTitle('Navigasi', theme),
                  _buildSidebarItem(
                    context,
                    assetPath: 'assets/images/home.png',
                    title: 'Beranda',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                  _buildSidebarItem(
                    context,
                    assetPath: 'assets/images/bisnis_ap.png',
                    title: 'Dashboard Bisnis AP',
                    isSelected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(ThemeData theme, {required Color surfaceColor, required bool isDark}) {
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceVariant : Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('assets/images/logo.png'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MUJ Apps',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Bisnis Anak Perusahaan',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildSidebarItem(
      BuildContext context, {
        required String assetPath,
        required String title,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isSelected ? theme.colorScheme.onSurface : theme.hintColor;
    final bgColor = isSelected ? (isDark ? Colors.grey[850] : Colors.grey[200]) : Colors.transparent;

    return Material(
      color: bgColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Image.asset(
                assetPath,
                width: 22,
                height: 22,
                color: color,
                errorBuilder: (ctx, e, st) => const Icon(Icons.error, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Data',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildDropdown(
                  label: 'Tahun',
                  value: _selectedYear,
                  values: _years,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedYear = value;
                      _selectedFilter = 'All';
                      _selectedFilterOption = 'All';
                    });
                  },
                ),
                _buildDropdown(
                  label: 'Filter',
                  value: _selectedFilter,
                  values: _availableFilters,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedFilter = value;
                      _selectedFilterOption = 'All';
                    });
                  },
                ),
                _buildDropdown(
                  label: 'Opsi Filter',
                  value: _availableFilterOptions.contains(_selectedFilterOption)
                      ? _selectedFilterOption
                      : 'All',
                  values: _availableFilterOptions,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedFilterOption = value;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Terapkan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButton<String>(
                value: value,
                icon: const Icon(Icons.keyboard_arrow_down),
                underline: const SizedBox(),
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                onChanged: onChanged,
                items: values
                    .map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySection(_CompanyMetrics company) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            company.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Column(
            children: company.metrics
                .map(
                  (metric) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MetricCard(
                  data: metric,
                  formatter: _numberFormatter,
                ),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;
  final NumberFormat formatter;

  const _MetricCard({required this.data, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: data.gradient),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: data.gradient.last.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(data.icon, color: data.gradient.last),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white38, thickness: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RKA',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formatter.format(data.rka),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Realisasi',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        formatter.format(data.realisasi),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      '${data.percentage.toStringAsFixed(2)} %',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCardData {
  final String title;
  final int rka;
  final int realisasi;
  final double percentage;
  final List<Color> gradient;
  final IconData icon;

  const _MetricCardData({
    required this.title,
    required this.rka,
    required this.realisasi,
    required this.percentage,
    required this.gradient,
    required this.icon,
  });
}

class _CompanyMetrics {
  final String name;
  final List<_MetricCardData> metrics;

  const _CompanyMetrics({required this.name, required this.metrics});
}