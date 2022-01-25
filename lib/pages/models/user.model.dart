import 'package:flutter/material.dart';

class User {
  String firstName;
  String lastName;
  String regNumber;
  String userClass;
  String parentMobileNumber;

  User({@required this.firstName,@required this.lastName, @required this.regNumber, @required this.userClass, @required this.parentMobileNumber });

  static User fromDB(String dbuser) {
    return new User(firstName: dbuser.split(':')[0],lastName: dbuser
        .split(':')[1], regNumber: dbuser.split(':')[2], userClass:dbuser.split(':')[3],parentMobileNumber:dbuser.split(':')[4] );
  }
}
