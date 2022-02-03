import 'dart:convert';
import 'dart:ffi';

import 'package:camera/camera.dart';
import 'package:face_net_authentication/pages/db/database.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:face_net_authentication/pages/profile.dart';
import 'package:face_net_authentication/pages/widgets/app_button.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/facenet.service.dart';
import 'package:face_net_authentication/services/ml_kit_service.dart';
import 'package:flutter/material.dart';
import '../home.dart';
import '../sign-in.dart';
import '../sign-up.dart';
import 'app_text_field.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:http/http.dart' as http;

class AuthActionButton extends StatefulWidget {
  AuthActionButton(this._initializeControllerFuture,
      {Key key,
      @required this.onPressed,
      @required this.isLogin,
      this.reload,
      this.isSignUp,
        this.setLoading,
      this.loading});

  final Future _initializeControllerFuture;
  final bool isLogin;
  final Function onPressed;
  final Function setLoading;
  final Function reload;
  final bool isSignUp;
  bool loading;

  @override
  _AuthActionButtonState createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  /// service injection
  final FaceNetService _faceNetService = FaceNetService();
  final DataBaseService _dataBaseService = DataBaseService();
  final CameraService _cameraService = CameraService();
  CameraDescription cameraDescription;
  MLKitService _mlKitService = MLKitService();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _firstNameTextEditingController =
      TextEditingController(text: '');
  final TextEditingController _lastNameTextEditingController =
      TextEditingController(text: '');

  final TextEditingController _emailTextEditingController =
      TextEditingController(text: '');
  final TextEditingController _phoneNumberTextEditingController =
  TextEditingController(text: '');


  User predictedUser;

  Future _signUp(BuildContext context) async {
    // _setLoading(true);
    widget.setLoading(true);

    /// gets predicted data from facenet service (user face detected)
    List predictedData = _faceNetService.predictedData;
    String firstName = _firstNameTextEditingController.text;
    String lastName = _lastNameTextEditingController.text;
    String email = _emailTextEditingController.text;
    String number = _phoneNumberTextEditingController.text;

    /// creates a new user in the 'database'

    var response = await _registerNewUser(firstName, lastName, email, number);

    print(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      await _dataBaseService.saveData(firstName, lastName, email, predictedData);

      const snackBar = SnackBar(
        content: Text('User registered successfully'),
      );
      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      // reload();
    } else {
      widget.setLoading(false);
      const snackBar = SnackBar(
        content: Text('Something went wrong try again'),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      throw Exception('Failed to create student.');
    }
    widget.setLoading(false);
    this._faceNetService.setPredictedData(null);
    Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) => MyHomePage()));
    // widget.reload();
  }

  Future _signIn(context) async {
    String password = _emailTextEditingController.text;

    if (this.predictedUser.email == password) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => Profile(
                    this.predictedUser.firstName,
                    imagePath: _cameraService.imagePath,
                  )));
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Wrong password!'),
          );
        },
      );
    }
  }

  Future<http.Response> _registerNewUser(
      String firstName, String lastName, String email, String number) async {
    return http.post(
      Uri.parse('https://www.edutrack.istart.co.zw/api/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
          <String, String>{'name': '$firstName $lastName', 'email': email, 'number' :number}),
    );
  }

  Future<http.Response> _checkInUser(String email, String name) async {
    return http.post(
      Uri.parse('https://www.edutrack.istart.co.zw/api/checkin'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'email': email}),
    );
  }

  String _predictUser() {
    String userAndPass = _faceNetService.predict();
    return userAndPass ?? null;
  }

  @override
  void initState() {
    super.initState();
    _startUp();
  }

  _setLoading(bool value) {
    setState(() {
      widget.loading = value;
    });
  }

  _startUp() async {
    _setLoading(true);

    List<CameraDescription> cameras = await availableCameras();

    /// takes the front camera
    cameraDescription = cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
    );

    // start the services
    await _faceNetService.loadModel();
    await _dataBaseService.loadDB();
    _mlKitService.initialize();

    _setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        try {
          // Ensure that the camera is initialized.
          await widget._initializeControllerFuture;
          // onShot event (takes the image and predict output)
          bool faceDetected = await widget.onPressed();

          if (faceDetected) {
            if (widget.isLogin) {
              var userAndPass = _predictUser();
              if (userAndPass != null) {
                this.predictedUser = User.fromDB(userAndPass);
              }
            }

            if (widget.isSignUp) {
              PersistentBottomSheetController bottomSheetController =
                  Scaffold.of(context)
                      .showBottomSheet((context) => signSheet(context));
              bottomSheetController.closed.whenComplete(() => widget.reload());
            } else {
              showDialog(
                context: context,
                builder: (context) {
                  Future.delayed(Duration(seconds: 5), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => SignIn(
                          cameraDescription: cameraDescription,
                        ),
                      ),
                    );
                  });
                  return AlertDialog(
                    content: widget.isLogin && predictedUser != null
                        ? Container(
                      child: Text(
                        'Check In ${predictedUser.firstName} ${predictedUser.lastName}',
                        style: TextStyle(fontSize: 20),
                      ),
                    )
                        : widget.isLogin
                        ? Container(
                        child: Text(
                          'Student not found 😞',
                          style: TextStyle(fontSize: 20),
                        ))
                        : null,
                  );
                },
              );
              if (widget.isLogin && predictedUser != null) {
                var response = await _checkInUser(this.predictedUser.email,
                    "$this.predictedUser.firstName $this.predictedUser.firstName");
                print(response.body);
                if (response.statusCode == 200 || response.statusCode == 201) {

                  const snackBar = SnackBar(
                    content: Text('Check in successfully'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                } else {
                  const snackBar = SnackBar(
                    content: Text('Something went wrong submitting to server'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  throw Exception('Failed to create to check in.');
                }
              }
            }
          }
        } catch (e) {
          // If an error occurs, log the error to the console.
          print(e);
        }
      },
      child: !widget.loading
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Color(0xFF0F0BDB),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 1,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              width: MediaQuery.of(context).size.width * 0.8,
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CAPTURE',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Icon(Icons.camera_alt, color: Colors.white)
                ],
              ),
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  signSheet(BuildContext context) {
    return  Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            child: Column(
              children: [
                !widget.isLogin
                    ? AppTextField(
                        controller: _firstNameTextEditingController,
                        labelText: "First Name",
                      )
                    : Container(),
                SizedBox(height: 10),
                !widget.isLogin
                    ? AppTextField(
                        controller: _lastNameTextEditingController,
                        labelText: "Last Name",
                      )
                    : Container(),
                SizedBox(height: 10),
                !widget.isLogin
                    ? AppTextField(
                        controller: _emailTextEditingController,
                        labelText: "Email",
                      )
                    : Container(),
                SizedBox(height: 10),
                !widget.isLogin
                    ? AppTextField(
                  controller: _phoneNumberTextEditingController,
                  labelText: "Phone Number",
                )
                    : Container(),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                widget.isLogin && predictedUser != null
                    ? AppButton(
                        text: 'LOGIN',
                        onPressed: () async {
                          _signIn(context);
                        },
                        icon: Icon(
                          Icons.login,
                          color: Colors.white,
                        ),
                      )
                    : !widget.isLogin
                        ? AppButton(
                            text: 'SIGN UP',
                            onPressed: () async {
                              await _signUp(context);
                            },
                            icon: Icon(
                              Icons.person_add,
                              color: Colors.white,
                            ),
                          )
                        : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
