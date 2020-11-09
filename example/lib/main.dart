import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ssl_pinning/flutter_ssl_pinning.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _PiningSslData {
  String serverURL = '';
  Map<String, String> headerHttp = Map();
  String allowedSHAFingerprint = '';
  int timeout = 0;
  Algorithm sha;
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  _PiningSslData _data = _PiningSslData();
  BuildContext scaffoldContext;

  @override
  initState() {
    super.initState();
  }

  check(
    String url,
    String fingerprint,
    Algorithm sha,
    Map<String, String> headerHttp,
    int timeout,
  ) async {
    List<String> allowedShA1FingerprintList = List();
    allowedShA1FingerprintList.add(fingerprint);

    try {
      // Platform messages may fail, so we use a try/catch PlatformException.
      bool valid = await flutterSslPinning.validating(
        serverURL: url,
        headerHttp: headerHttp,
        algorithm: sha,
        allowedSHAFingerprints: allowedShA1FingerprintList,
        timeout: timeout,
      );

      if (!mounted) return;

      Scaffold.of(scaffoldContext).showSnackBar(
        SnackBar(
          content:
              Text(valid ? 'Connection secured' : 'Connection not secured'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } on FlutterSslPinningException catch (e) {
      print(e.code);
      Scaffold.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void submit() {
    // First validate form.
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      this.check(
        _data.serverURL,
        _data.allowedSHAFingerprint,
        _data.sha,
        _data.headerHttp,
        _data.timeout,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    this.scaffoldContext = context;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter SSL Pinning'),
        ),
        body: Builder(
          builder: (BuildContext context) {
            this.scaffoldContext = context;
            return Container(
              padding: EdgeInsets.all(20.0),
              child: Form(
                key: this._formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'https://yourdomain.com',
                        labelText: 'URL',
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter some url';
                        }

                        return null;
                      },
                      onSaved: (String value) {
                        this._data.serverURL = value;
                      },
                    ),
                    DropdownButton(
                      items: [
                        DropdownMenuItem(
                          child: Text(Algorithm.sha1.toString()),
                          value: Algorithm.sha1,
                        ),
                        DropdownMenuItem(
                          child: Text(Algorithm.sha256.toString()),
                          value: Algorithm.sha256,
                        )
                      ],
                      value: _data.sha,
                      isExpanded: true,
                      onChanged: (Algorithm val) {
                        setState(() {
                          this._data.sha = val;
                        });
                      },
                    ),
                    TextFormField(
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'OO OO OO OO OO OO OO OO OO OO',
                        labelText: 'Fingerprint',
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter some fingerprint';
                        }

                        return null;
                      },
                      onSaved: (String value) {
                        this._data.allowedSHAFingerprint = value;
                      },
                    ),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: '60',
                      decoration: InputDecoration(
                        hintText: '60',
                        labelText: 'Timeout',
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter some timeout';
                        }

                        return null;
                      },
                      onSaved: (String value) {
                        this._data.timeout = int.parse(value);
                      },
                    ),
                    Container(
                      child: RaisedButton(
                        child: Text(
                          'Check',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () => submit(),
                        color: Colors.blue,
                      ),
                      margin: EdgeInsets.only(top: 20.0),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
