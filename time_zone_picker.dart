import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

class TimeZonePicker {
  static Future<TimeZone> launch(BuildContext context) async {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TimeZonePickerWidget()),
    );
  }
}

class TimeZonePickerWidget extends StatefulWidget {
  @override
  _TimeZonePickerWidgetState createState() => _TimeZonePickerWidgetState();
}

class _TimeZonePickerWidgetState extends State<TimeZonePickerWidget> {
  LocationDatabase _database;
  Map<String, TimeZone> _timeZoneData = Map<String, TimeZone>();
  TextEditingController _controller;
  List<String> _suggestions = List();
  List<String> _displaySuggestions = List();
  List<String> _initialSuggestions = List();
  TimeZone _returnTimeZone;
  Future<ByteData> _byteData;

  Future<ByteData> _setup() async {
    final byteData = await rootBundle.load('packages/timezone/data/2019c.tzf');
    initializeDatabase(byteData.buffer.asUint8List());
    _database = timeZoneDatabase;
    final locations = _database.locations;

    locations.forEach((k, v) {
      if (!_timeZoneData.containsKey(v.currentTimeZone.abbr)) {
        _timeZoneData[v.currentTimeZone.abbr] = v.currentTimeZone;
        _initialSuggestions.add(v.currentTimeZone.abbr);
      }
      _timeZoneData[k
          .replaceAll(RegExp('/'), ', ')
          .replaceAll(RegExp('_'), ' ')] = v.currentTimeZone;
    });
    return byteData;
  }

  void _getTimezoneSuggestions() {
    setState(() {
      _suggestions = List();
      if (_controller.text.isEmpty) return;

      _timeZoneData.forEach((k, v) {
        if (k.startsWith(_controller.text.toLowerCase()) ||
            k.toLowerCase().contains(_controller.text.toLowerCase())) {
          _suggestions.add(k);
        }
      });
    });
  }

  @override
  void initState() {
    _byteData = _setup();
    _controller = TextEditingController();
    _controller.addListener(_getTimezoneSuggestions);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              decoration: new BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[400],
                    blurRadius: 3,
                    spreadRadius: 0,
                    offset: Offset(
                      0,
                      0,
                    ),
                  )
                ],
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: Colors.white,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.grey[700],
                        ),
                        onPressed: () =>
                            Navigator.pop(context, _returnTimeZone),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter a location, time zone, or offset',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      Container(
                        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[700],
                          ),
                          onPressed: () => setState(() {
                            _controller.clear();
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 12,
            ),
            FutureBuilder(
                future: _byteData,
                builder: (context, snapshot) {
                  print('built');
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (_controller.text.isEmpty) {
                      _displaySuggestions = _initialSuggestions;
                    } else if (_suggestions.length == 0) {
                      return Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          child: Text(
                            'Your search did not return and matches',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                      );
                    } else if (_controller.text.isNotEmpty) {
                      _displaySuggestions = _suggestions;
                    }
                  }

                  return Expanded(
                      child: ListView.builder(
                    itemCount: _displaySuggestions.length,
                    itemBuilder: (context, index) {
                      final key = _displaySuggestions[index];
                      return InkWell(
                        onTap: () {
                          _returnTimeZone = _timeZoneData[key];
                          Navigator.pop(context, _returnTimeZone);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.public,
                                color: Colors.grey[700],
                              ),
                              SizedBox(
                                width: 21,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    _timeZoneData[key].abbr,
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (key == _timeZoneData[key].abbr)
                                    Text(
                                      'Timezone',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  if (key != _timeZoneData[key].abbr)
                                    Text(
                                      key,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ));
                }),
          ],
        ),
      ),
    );
  }
}
