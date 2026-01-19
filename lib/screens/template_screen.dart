import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

import '../widgets/bottom_sheet_widget.dart';

class TemplateScreen extends StatefulWidget {
  final Map<String, dynamic> clubData;
  final String email;

  const TemplateScreen(
      {super.key, required this.clubData, required this.email});

  @override
  _TemplateScreenState createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  String _selectedTemplate = 'Gameday';
  String? _selectedSeason;
  String? _selectedTeam;
  String? _selectedFixture;

  String? _clubLogo;

  List<Map<String, dynamic>> _seasons = [];
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _fixtures = [];

  Map<String, dynamic> _clubData = {};

  bool _generateButtonLoading = false;
  bool _errorMessage = false;

  // Update this to your Railway URL when deployed
  final String baseUrl = 'http://localhost:3000/';

  final dropdownInputDecoration = InputDecoration(
    contentPadding: const EdgeInsets.all(15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Color(0xFFE3E5E5),
        width: 1.4,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Color(0xFFE3E5E5),
        width: 1.4,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Color(0xFFE3E5E5),
        width: 1.4,
      ),
    ),
  );

  final dropdownBoxShadow = BoxShadow(
    color: Colors.grey.withOpacity(0.5),
    spreadRadius: 1.2,
    blurRadius: 4,
    offset: const Offset(0, 2),
  );

  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();

  @override
  void initState() {
    super.initState();
    _readClubData(widget.clubData);
  }

  List<Widget> dropdownLabel(String label) {
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
      const SizedBox(height: 5),
    ];
  }

  void _readClubData(Map<String, dynamic> clubData) {
    try {
      setState(() {
        _errorMessage = false;
        _clubData = clubData;

        // Extract seasons from the new structure
        if (_clubData['seasons'] != null && _clubData['seasons'].isNotEmpty) {
          _seasons = List<Map<String, dynamic>>.from(_clubData['seasons']);
          
          // Auto-select first season
          if (_seasons.isNotEmpty) {
            _selectedSeason = _seasons.first['seasonName'];
            _updateTeams(_seasons.first['seasonName']);
          }
        } else {
          _errorMessage = true;
          _showSnackBar('No data available for $_selectedTemplate');
          _seasons = [];
          _teams = [];
          _fixtures = [];
        }

        _clubLogo = _clubData['clubLogo'];
      });
    } catch (e) {
      _showErrorMessage('An error occurred: $e');
    }
  }

  void _updateTeams(String selectedSeason) {
    setState(() {
      final season = _seasons.firstWhere(
        (s) => s['seasonName'] == selectedSeason,
        orElse: () => {},
      );

      if (season.isNotEmpty && season['teams'] != null) {
        _teams = List<Map<String, dynamic>>.from(season['teams']);
        
        // Reset selections
        _selectedTeam = null;
        _selectedFixture = null;

        // Auto-select first team
        if (_teams.isNotEmpty) {
          _selectedTeam = _teams.first['teamName'];
          _updateFixtures(_teams.first['teamName']);
        }
      }
    });
  }

  void _updateFixtures(String selectedTeam) {
    setState(() {
      final team = _teams.firstWhere(
        (t) => t['teamName'] == selectedTeam,
        orElse: () => {},
      );

      if (team.isNotEmpty && team['fixtures'] != null) {
        _fixtures = List<Map<String, dynamic>>.from(team['fixtures']);
        
        // Reset fixture selection
        _selectedFixture = null;
      }
    });
  }

  Future<void> _generateImage() async {
    if (_selectedFixture == null) {
      _showSnackBar('Please select a fixture');
      _btnController.stop();
      return;
    }

    setState(() {
      _generateButtonLoading = true;
    });

    // Find the selected season to get competition and association info
    final selectedSeasonData = _seasons.firstWhere(
      (s) => s['seasonName'] == _selectedSeason,
      orElse: () => {},
    );

    // Find the selected team to get club logo
    final selectedTeamData = _teams.firstWhere(
      (t) => t['teamName'] == _selectedTeam,
      orElse: () => {},
    );

    // Find the selected fixture data
    final selectedFixtureData = _fixtures.firstWhere(
      (f) => f['fixtureId'] == _selectedFixture,
      orElse: () => {},
    );

    if (selectedFixtureData.isEmpty) {
      _showSnackBar('Fixture not found');
      _btnController.stop();
      return;
    }

    try {
      final templateEndpoints = {
        'Gameday': 'generate-gameday-image',
        // Add other templates when ready
        // 'Lineup': 'generate-players-image',
        // 'Match Result': 'generate-result-image',
      };

      final url = '$baseUrl${templateEndpoints[_selectedTemplate]}';

      // Format the fixture name for display
      final fixtureName = '${selectedFixtureData['homeTeam']} vs ${selectedFixtureData['awayTeam']}';
      final fixtureDate = selectedFixtureData['date'] ?? '';
      final fixtureTime = selectedFixtureData['time'] ?? '';
      final venue = selectedFixtureData['venueName'] ?? '';
      final venueSurface = selectedFixtureData['venueSurface'] ?? '';
      
      final fullVenue = venueSurface.isNotEmpty 
          ? '$venue / $venueSurface' 
          : venue;

      // Get competition name and association logo from season data
      final competitionName = selectedSeasonData['competitionName'] ?? '';
      final associationLogo = selectedSeasonData['associationLogo'] ?? 'https://pngfre.com/wp-content/uploads/Cricket-14-1.png';
      
      // Get team logos from fixture data (now included in response)
      final homeTeamLogo = selectedFixtureData['homeTeamLogo'] ?? 'https://pngfre.com/wp-content/uploads/Cricket-14-1.png';
      final awayTeamLogo = selectedFixtureData['awayTeamLogo'] ?? 'https://pngfre.com/wp-content/uploads/Cricket-14-1.png';

      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'teamA': selectedFixtureData['homeTeam'] ?? '',
          'teamB': selectedFixtureData['awayTeam'] ?? '',
          'gameDate': '$fixtureDate ${fixtureTime}',
          'competitionName': competitionName,
          'teamALogoUrl': homeTeamLogo,
          'teamBLogoUrl': awayTeamLogo,
          'gameFormat': selectedFixtureData['roundName'] ?? '',
          'gameVenue': fullVenue,
          'associationLogo': associationLogo,
          'userEmail': widget.email,
        }),
      );

      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return ImageBottomSheet(
              imageBytes: imageBytes,
              onRedesign: () {
                Navigator.of(context).pop();
              },
              imageName: '$_selectedTemplate-${_selectedTeam ?? 'team'}-${selectedFixtureData['roundName'] ?? 'fixture'}.png',
            );
          },
        );
      } else {
        _showSnackBar('Failed to generate image');
      }
      
      setState(() {
        _generateButtonLoading = false;
      });
      _btnController.stop();
    } catch (e) {
      setState(() {
        _generateButtonLoading = false;
      });
      _btnController.stop();
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        backgroundColor: const Color(0xFF7A5FFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    _showSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaPadding = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(249, 253, 254, 1),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                  right: 40.0, left: 40.0, top: safeAreaPadding, bottom: 10),
              width: double.infinity,
              height: 120 + safeAreaPadding,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(60, 17, 185, 1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Welcome to Sportal",
                        style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 0.4),
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_clubLogo != null)
                    CircleAvatar(
                      radius: 30.0,
                      backgroundImage: NetworkImage(_clubLogo!),
                    )
                  else
                    const CircleAvatar(
                      radius: 30.0,
                      child: Icon(Icons.sports, size: 30),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Template Dropdown (currently only Gameday works)
                  ...dropdownLabel("Template"),
                  Container(
                    decoration: BoxDecoration(
                        boxShadow: [dropdownBoxShadow],
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      value: _selectedTemplate,
                      items: ['Gameday'] // Only Gameday for now
                          .map((template) => DropdownMenuItem(
                              value: template, child: Text(template)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTemplate = newValue ?? 'Gameday';
                        });
                      },
                      decoration: dropdownInputDecoration,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Season Dropdown
                  ...dropdownLabel("Season"),
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [dropdownBoxShadow],
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      value: _selectedSeason,
                      items: _seasons
                          .map<DropdownMenuItem<String>>((season) => DropdownMenuItem<String>(
                                value: season['seasonName'] as String,
                                child: Text(season['seasonName'] as String),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSeason = newValue!;
                          _updateTeams(newValue);
                        });
                      },
                      decoration: dropdownInputDecoration,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Team Dropdown
                  ...dropdownLabel("Team"),
                  Container(
                    decoration: BoxDecoration(
                        boxShadow: [dropdownBoxShadow],
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      value: _selectedTeam,
                      items: _teams
                          .map<DropdownMenuItem<String>>((team) => DropdownMenuItem<String>(
                              value: team['teamName'] as String,
                              child: Text(team['teamName'] as String)))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedTeam = newValue!;
                          _updateFixtures(newValue);
                        });
                      },
                      decoration: dropdownInputDecoration,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Fixture Dropdown
                  ...dropdownLabel("Fixture"),
                  Container(
                    decoration: BoxDecoration(
                        boxShadow: [dropdownBoxShadow],
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      isExpanded: true,
                      value: _selectedFixture,
                      items: _fixtures
                          .map<DropdownMenuItem<String>>((fixture) => DropdownMenuItem<String>(
                                value: fixture['fixtureId'] as String,
                                child: Text(
                                  '${fixture['roundAbbr'] ?? fixture['roundName']}: ${fixture['homeTeam']} vs ${fixture['awayTeam']}',
                                ),
                              ))
                          .toList(),
                      onChanged: (newValue) => setState(() {
                        _selectedFixture = newValue!;
                      }),
                      decoration: dropdownInputDecoration,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Generate Button
                  RoundedLoadingButton(
                      controller: _btnController,
                      color: _errorMessage
                          ? Colors.blueGrey
                          : const Color.fromRGBO(60, 17, 185, 1),
                      onPressed: _generateButtonLoading || _errorMessage
                          ? null
                          : _generateImage,
                      child: const Text('Generate',
                          style: TextStyle(color: Colors.white))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}