import 'package:flutter/material.dart';
import 'dart:convert'; // For json decoding
import 'package:http/http.dart' as http;

import '../widgets/bottom_sheet_widget.dart'; // For making HTTP requests

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
  Map<String, dynamic> _clubDataPlayers = {};

  bool _generateButtonLoading = false;

  @override
  void initState() {
    super.initState();
    _readClubData(widget.email, widget.clubData);
    _fetchPlayerClubData();
  }

  Future<void> _fetchPlayerClubData() async {
    final response = await http.get(Uri.parse(
        'https://sportal-backend.onrender.com/get-club-info-player-filter/${widget.email}'));

    if (response.statusCode == 200) {
      setState(() {
        _clubDataPlayers = jsonDecode(response.body);
      });
    }
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

  Future<void> _readClubData(
      String email, Map<String, dynamic> clubData) async {
    try {
      setState(() {
        _clubData = clubData;
        _associations = (_clubData['association'] as List)
            .map((assoc) => assoc['associationName'] as String)
            .toList();

        if (_associations.isNotEmpty) {
          _selectedAssociation = _associations.first;
          _updateCompetitions(_associations.first);
        }

        _clubLogo = _clubData['clubLogo'];
      });
    } catch (e) {
      _showErrorMessage('An error occurred: $e');
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
        _selectedCompetition = _competitions.first;
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
        _selectedSeason = _seasons.first;
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
        _selectedTeam = _teams.first;
        _updateFixtures(_teams.first, selectedSeason, selectedCompetition,
            selectedAssociation);
      }
    });
  }

  void _updateFixtures(String selectedTeam, String selectedSeason,
      String selectedCompetition, String selectedAssociation) {
    setState(() {
      _selectedFixture = null;

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
    setState(() {
      _generateButtonLoading = true;
    });
    if (_selectedFixture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a fixture.')));
          setState(() {
      _generateButtonLoading = false;
    });
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
      final url = _selectedTemplate == 'Gameday' ? 'https://sportal-backend.onrender.com/generate-gameday-image' : 'https://sportal-backend.onrender.com/generate-players-image';

      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({
          'teamA': selectedFixture['teamA'],
          'teamB': selectedFixture['teamB'],
          'gameDate': selectedFixture['fixtureDate'],
          "competitionName": _selectedCompetition ?? "",
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
          "playerList": selectedFixture['playerList'],
          "fixtureName": selectedFixture['fixtureName']
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
      setState(() {
        _generateButtonLoading = false;
      });
    } catch (e) {
      setState(() {
        _generateButtonLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showErrorMessage(String message) {
    MediaQuery.paddingOf(context).top;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaPadding = MediaQuery.paddingOf(context).top;
    print("TOP APP BAR HEIGHT: ");
    print(safeAreaPadding);
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
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Align items horizontally
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Align items vertically
                children: [
                  const Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center text vertically
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align text to the left
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
                  CircleAvatar(
                    radius: 30.0,
                    backgroundImage: NetworkImage(
                      _clubLogo ?? '', // Replace with the actual image URL
                    ),
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
                    items: ['Gameday', 'Starting XI']
                        .map((template) => DropdownMenuItem(
                            value: template, child: Text(template)))
                        .toList(),
                    onChanged: (newValue) => _updateTemplate(newValue),
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
                        .map((team) =>
                            DropdownMenuItem(value: team, child: Text(team)))
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
                    onPressed: _generateButtonLoading ? null : _generateImage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 90, vertical: 20),
                      backgroundColor: const Color.fromRGBO(60, 17, 185, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: SizedBox(
                      width: 100,
                      height: 20,
                      child: _generateButtonLoading
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Center(
                              child: Text(
                                'Generate',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  _updateTemplate(String? newValue) {
    setState(() {
      _clubData = newValue == 'Gameday' ? widget.clubData : _clubDataPlayers;
      _selectedTemplate = newValue ?? 'Gameday';

      _selectedAssociation = null;
      _selectedCompetition = null;
      _selectedSeason = null;
      _selectedTeam = null;
      _selectedFixture = null;


      _associations = (_clubData['association'] as List)
          .map((assoc) => assoc['associationName'] as String)
          .toList();
    });
  }
}
