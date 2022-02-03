import 'package:flutter/material.dart';

class User {
  String firstName;
  String lastName;
  String email;

  User({@required this.firstName,@required this.lastName, @required this.email });

  static User fromDB(String dbuser) {
    return new User(firstName: dbuser.split(':')[0],lastName: dbuser
        .split(':')[1], email: dbuser.split(':')[2]);
  }
}
