import 'package:flutter/material.dart';
import 'dart:convert'; // For json decoding
import 'package:http/http.dart' as http;

import '../widgets/bottom_sheet_widget.dart'; // For making HTTP requests

class TemplateScreen extends StatefulWidget {
  final String email; // Add email as a required parameter

  const TemplateScreen(
      {super.key, required this.email}); // Constructor to accept email

  @override
  _TemplateScreenState createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  String _selectedTemplate = 'Gameday';
  String? _selectedAssociation;
  String? _selectedCompetition;
  String? _selectedSeason;
  String? _selectedTeam;
  String? _selectedFixture;

  String? _clubLogo;

  List<String> _associations = [];
  List<String> _competitions = [];
  List<String> _seasons = [];
  List<String> _teams = [];
  List<String> _fixtures = [];

  Map<String, dynamic> _clubData = {};
  bool _isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchClubData(widget.email);
  }

  List<Widget> dropdownLabel(String label) {
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(label),
      ),
      const SizedBox(
        height: 5,
      ),
    ];
  }

  Future<void> _fetchClubData(String email) async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });

    try {
      final response = await http.get(Uri.parse(
          'https://sportal-backend.onrender.com/get-club-info/$email'));

      if (response.statusCode == 200) {
        setState(() {
          _clubData = jsonDecode(response.body);
          _associations = (_clubData['association'] as List)
              .map((assoc) => assoc['associationName'] as String)
              .toList();

          if (_associations.isNotEmpty) {
            _updateCompetitions(_associations.first);
          }

          _clubLogo = _clubData['clubLogo'];

        });
      } else {
        // Handle error and show a message
        _showErrorMessage('Failed to load club data. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('An error occurred: $e');
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  void _updateCompetitions(String selectedAssociation) {
    setState(() {
      final association = _clubData['association'].firstWhere(
          (assoc) => assoc['associationName'] == selectedAssociation);

      _competitions = (association['competitions'] as List)
          .map((comp) => comp['competitionName'] as String)
          .toSet() // Use a Set to ensure uniqueness
          .toList();

      // Reset selections to ensure the values are valid
      _selectedCompetition = null;
      _selectedSeason = null;
      _selectedTeam = null;
      _selectedFixture = null;

      if (_competitions.isNotEmpty) {
        _updateSeasons(_competitions.first, selectedAssociation);
      }
    });
  }

  void _updateSeasons(String selectedCompetition, String selectedAssociation) {
    setState(() {
      final association = _clubData['association'].firstWhere(
          (assoc) => assoc['associationName'] == selectedAssociation);

      final competition = (association['competitions'] as List)
          .firstWhere((comp) => comp['competitionName'] == selectedCompetition);

      _seasons = (competition['seasons'] as List)
          .map((season) => season['seasonName'] as String)
          .toSet() // Ensure uniqueness
          .toList();

      // Reset selections as above
      _selectedSeason = null;
      _selectedTeam = null;
      _selectedFixture = null;

      if (_seasons.isNotEmpty) {
        _updateTeams(_seasons.first, selectedCompetition, selectedAssociation);
      }
    });
  }

  void _updateTeams(String selectedSeason, String selectedCompetition,
      String selectedAssociation) {
    setState(() {
      final association = _clubData['association'].firstWhere(
          (assoc) => assoc['associationName'] == selectedAssociation);

      final competition = (association['competitions'] as List)
          .firstWhere((comp) => comp['competitionName'] == selectedCompetition);

      final season = (competition['seasons'] as List)
          .firstWhere((season) => season['seasonName'] == selectedSeason);

      _teams = (season['teams'] as List)
          .map((team) => team['teamName'] as String)
          .toSet() // Ensure uniqueness
          .toList();

      // Reset selections
      _selectedTeam = null;
      _selectedFixture = null;

      if (_teams.isNotEmpty) {
        _updateFixtures(_teams.first, selectedSeason, selectedCompetition,
            selectedAssociation);
      }
    });
  }

  void _updateFixtures(String selectedTeam, String selectedSeason,
      String selectedCompetition, String selectedAssociation) {
    setState(() {
      final association = _clubData['association'].firstWhere(
          (assoc) => assoc['associationName'] == selectedAssociation);

      final competition = (association['competitions'] as List)
          .firstWhere((comp) => comp['competitionName'] == selectedCompetition);

      final season = (competition['seasons'] as List)
          .firstWhere((season) => season['seasonName'] == selectedSeason);

      final team = (season['teams'] as List)
          .firstWhere((team) => team['teamName'] == selectedTeam);

      _fixtures = (team['fixtures'] as List)
          .map((fixture) => fixture['fixtureName'] as String)
          .toList();
    });
  }

  Future<void> _generateImage() async {
    if (_selectedFixture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a fixture.')));
      return;
    }

    // Use the additional parameters to find the correct fixture
    final selectedFixture = (_clubData['association'] as List)
        .expand((assoc) => (assoc['competitions'] as List).expand((comp) =>
            (comp['seasons'] as List).expand((season) => (season['teams']
                    as List)
                .expand((team) => (team['fixtures'] as List).where((fixture) {
                      // Add additional conditions to uniquely identify the fixture
                      return fixture['fixtureName'] == _selectedFixture &&
                          season['seasonName'] == _selectedSeason &&
                          team['teamName'] == _selectedTeam;
                    })))))
        .firstWhere((fixture) =>
            true); // No need for condition since we've filtered above

    try {
      final response = await http.post(
        Uri.parse(
            'https://sportal-backend.onrender.com/generate-gameday-image'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'teamA': selectedFixture['teamA'],
          'teamB': selectedFixture['teamB'],
          'gameDate': selectedFixture['fixtureDate'],
          "seasonName": _selectedSeason ?? "",
          "teamALogoUrl": selectedFixture['teamALogo'] ??
              "https://pngfre.com/wp-content/uploads/Cricket-14-1.png", // New parameter
          "teamBLogoUrl": selectedFixture['teamBLogo'] ??
              "https://pngfre.com/wp-content/uploads/Cricket-14-1.png", // New parameter
          "gameFormat":
              selectedFixture['fixtureFormat'] ?? "One Day", // New parameter
          "gameVenue": selectedFixture['fixtureVenue'] ?? "",
          "sponsor1LogoUrl": selectedFixture['sponsor1LogoUrl'] ??
              "https://pngfre.com/wp-content/uploads/Cricket-14-1.png", // New parameter
          "associationLogo": (_clubData['association'] as List).firstWhere(
                  (assoc) => assoc['associationName'] == _selectedAssociation)[
              'associationLogo'],
          "userEmail": widget.email,
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
            );
          },
        );
      } else {}
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(249, 253, 254, 1),
      body: _isLoading // Show loading indicator
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(child:  Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal:  40.0, vertical: 15), // Add padding
                  width: double.infinity, 
                  height: 150,// Make the box full width
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(
                        60, 17, 185, 1), // Purple background color
                    borderRadius: BorderRadius.only(
                      bottomLeft:
                          Radius.circular(30), // Rounded corners at the bottom
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // Align text and image
                    children: [
                      // Column for text, aligned to the left
                      const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Align text to the left
                        children: [
                          SizedBox(height: 30),
                          Text(
                            'Hello',
                            style: TextStyle(
                              color: Colors.white, // White text color
                              fontSize: 30.0, // Font size
                              fontWeight: FontWeight.bold, // Bold text
                            ),
                          ),
                          Text(
                            "Welcome to Sportal",
                            style: TextStyle(
                              color: Color.fromRGBO(255, 255, 255,
                                  0.4), // White text with opacity
                              fontSize: 15.0, // Font size
                              fontWeight: FontWeight.bold, // Bold text
                            ),
                          ),
                        ],
                      ),
                      // Circular image on the right
                      CircleAvatar(
                        radius: 30.0, // Adjust the size of the circular image
                        backgroundImage: NetworkImage(
                            _clubLogo ?? ''), // Replace with the actual image URL
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      children: [
                        ...dropdownLabel("Template"),
                        DropdownButtonFormField<String>(
                          value: _selectedTemplate,
                          items: ['Gameday']
                              .map((template) => DropdownMenuItem(
                                  value: template, child: Text(template)))
                              .toList(),
                          onChanged: (newValue) =>
                              setState(() => _selectedTemplate = newValue!),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...dropdownLabel("Association"),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedAssociation,
                          items: _associations
                              .map((association) => DropdownMenuItem(
                                  value: association, child: Text(association)))
                              .toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedAssociation = newValue!;
                              _updateCompetitions(newValue);
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...dropdownLabel("Competition"),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedCompetition,
                          items: _competitions
                              .map((competition) => DropdownMenuItem(
                                  value: competition, child: Text(competition)))
                              .toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedCompetition = newValue!;
                              _updateSeasons(newValue, _selectedAssociation!);
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...dropdownLabel("Season"),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedSeason,
                          items: _seasons
                              .map((season) => DropdownMenuItem(
                                  value: season, child: Text(season)))
                              .toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedSeason = newValue!;
                              _updateTeams(newValue, _selectedCompetition!,
                                  _selectedAssociation!);
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...dropdownLabel("Grade"),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedTeam,
                          items: _teams
                              .map((team) => DropdownMenuItem(
                                  value: team, child: Text(team)))
                              .toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedTeam = newValue!;
                              _updateFixtures(newValue, _selectedSeason!,
                                  _selectedCompetition!, _selectedAssociation!);
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...dropdownLabel("Round"),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedFixture,
                          items: _fixtures
                              .map((fixture) => DropdownMenuItem(
                                  value: fixture, child: Text(fixture)))
                              .toList(),
                          onChanged: (newValue) => setState(() {
                            _selectedFixture = newValue!;
                          }),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        ElevatedButton(
                          onPressed: _generateImage,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 90, vertical: 10),
                            backgroundColor:
                                const Color.fromRGBO(60, 17, 185, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const Text(
                            'Generate',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w300),
                          ),
                        ),
                      ],
                    ),
                  
                )
              ],
            )),
    );
  }
}
