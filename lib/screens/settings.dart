import 'package:file_picker/file_picker.dart';
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';

class Settings {
  Duration focusDuration = const Duration(minutes: 27);
  Duration breakDuration = const Duration(minutes: 3);

  AssetSource alarmSource = AssetSource("EarlyRiser.mp3");
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings});

  final Settings settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Settings settings = Settings();
  final _formKey = GlobalKey<FormState>();

  var sounds = <String>[] = [];

  void _pickSoundFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        settings.alarmSource = AssetSource(result.files.single.path!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DefaultAssetBundle.of(context)
          .loadString("AssetManifest.json")
          .then((String manifest) {
        var options = json
            .decode(manifest)
            .keys
            .where((String key) => key.endsWith(".mp3"))
            .toList();
        setState(() {
          sounds = options;
        });
      });
      setState(() {
        settings = widget.settings;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
        ),
        body: Center(
            child: SizedBox(
                height: double.infinity,
                width: 400.0,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Form(
                          key: _formKey,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                TextFormField(
                                  keyboardType: TextInputType.number,
                                  initialValue: settings.focusDuration.inMinutes
                                      .toString(),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      settings.focusDuration =
                                          Duration(minutes: int.parse(value));
                                    });
                                  },
                                  decoration: const InputDecoration(
                                      labelText: "Focus Duration"),
                                ),
                                TextFormField(
                                  keyboardType: TextInputType.number,
                                  initialValue: settings.breakDuration.inMinutes
                                      .toString(),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      settings.breakDuration =
                                          Duration(minutes: int.parse(value));
                                    });
                                  },
                                  decoration: const InputDecoration(
                                      labelText: "Break Duration"),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField(
                                        items: sounds.map((String sound) {
                                          return DropdownMenuItem(
                                              value: sound, child: Text(sound));
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            settings.alarmSource =
                                                AssetSource(value.toString());
                                          });
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.folder),
                                      onPressed: _pickSoundFile,
                                    )
                                  ],
                                ),
                                ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        Navigator.of(context).pop(settings);
                                      }
                                    },
                                    child: const Text("Submit"))
                              ]))
                    ]))));
  }
}
