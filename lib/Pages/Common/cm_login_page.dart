import 'package:flutter/material.dart';
import 'package:mockup/Colors/AppColors.dart';
import 'package:mockup/Pages/Parent%20Pages/pr_main_shell.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_main_shell.dart';
import 'package:mockup/Pages/Driver%20Pages/dv_status_page.dart';

class CmLoginPage extends StatefulWidget {
  const CmLoginPage({super.key});

  @override
  State<CmLoginPage> createState() => _CmLoginPageState();
}

class _CmLoginPageState extends State<CmLoginPage> {
  String roleSelected = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Image.asset('assets/images/logo.png'),
            //Container wrapping a Column Containing Text & Fields
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF1A2B48),
                  borderRadius: BorderRadiusGeometry.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  spacing: 10,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(
                        "Welcome to Pasaty!",
                        style: TextStyle(fontSize: 28, color: Colors.white),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Phone Number:",
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(
                          width: 350,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "07XX XXX XXXX",
                              prefixIcon: Icon(Icons.phone_android),
                              // border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Role:", style: TextStyle(color: Colors.white),),
                        SizedBox(
                          width: 350,
                          child: DropdownButtonFormField<String>(
                            items: ["Driver", "Parent", "Staff"]
                                .map(
                                  (e) => DropdownMenuItem(value: e, child: Text(e)),
                                )
                                .toList(),
                            onChanged: (value) {
                              roleSelected = value!;
                            },
                            decoration: InputDecoration(
                              hintText: "Select Role",
                              prefixIcon: Icon(Icons.person),
                              // border: OutlineInputBorder()
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      width: 104,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (roleSelected == "Driver") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DvMainShell(),
                              ),
                            );
                          } else if (roleSelected == "Parent") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrMainShell(),
                              ),
                            );
                          } else if (roleSelected == "Staff") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DvMainShell(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [Text("Login"), Icon(Icons.arrow_forward)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
