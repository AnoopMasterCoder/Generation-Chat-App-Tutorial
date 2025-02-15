import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:generation/Backend/firebase/OnlineDatabaseManagement/cloud_data_management.dart';
import 'package:generation/Backend/sqlite_management/local_database_management.dart';
import 'package:generation/FrontEnd/Services/ChatManagement/chat_screen.dart';
import 'package:generation/FrontEnd/Services/search_screen.dart';
import 'package:generation/Global_Uses/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:generation/Global_Uses/enum_generation.dart';
import 'package:loading_overlay/loading_overlay.dart';

import 'package:animations/animations.dart';

class ChatAndActivityScreen extends StatefulWidget {
  const ChatAndActivityScreen({Key? key}) : super(key: key);

  @override
  _ChatAndActivityScreenState createState() => _ChatAndActivityScreenState();
}

class _ChatAndActivityScreenState extends State<ChatAndActivityScreen> {
  bool _isLoading = false;
  final List<String> _allUserConnectionActivity = ['Generation', 'Samarpan'];
  final List<String> _allConnectionsUserName = [];

  final CloudStoreDataManagement _cloudStoreDataManagement =
      CloudStoreDataManagement();

  final LocalDatabase _localDatabase = LocalDatabase();

  static final FirestoreFieldConstants _firestoreFieldConstants =
      FirestoreFieldConstants();

  /// For New Connected User Data Entry
  Future<void> _checkingForNewConnection(
      QueryDocumentSnapshot<Map<String, dynamic>> queryDocumentSnapshot,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (mounted) {
      setState(() {
        this._isLoading = true;
      });
    }

    final List<dynamic> _connectionRequestList =
        queryDocumentSnapshot.get(_firestoreFieldConstants.connectionRequest);

    _connectionRequestList.forEach((connectionRequestData) {
      if (connectionRequestData.values.first.toString() ==
              OtherConnectionStatus.Invitation_Accepted.toString() ||
          connectionRequestData.values.first.toString() ==
              OtherConnectionStatus.Request_Accepted.toString()) {
        docs.forEach((everyDocument) async {
          if (everyDocument.id == connectionRequestData.keys.first.toString()) {
            final String _connectedUserName =
                everyDocument.get(_firestoreFieldConstants.userName);
            final String _token =
                everyDocument.get(_firestoreFieldConstants.token);
            final String _about =
                everyDocument.get(_firestoreFieldConstants.about);
            final String _accCreationDate =
                everyDocument.get(_firestoreFieldConstants.creationDate);
            final String _accCreationTime =
                everyDocument.get(_firestoreFieldConstants.creationTime);

            if (mounted) {
              setState(() {
                if (!this._allConnectionsUserName.contains(_connectedUserName))
                  this._allConnectionsUserName.add(_connectedUserName);
              });
            }



            final bool _newConnectionUserNameInserted =
                await _localDatabase.insertOrUpdateDataForThisAccount(
                    userName: _connectedUserName,
                    userMail: everyDocument.id,
                    userToken: _token,
                    userAbout: _about,
                    userAccCreationDate: _accCreationDate,
                    userAccCreationTime: _accCreationTime);

            if (_newConnectionUserNameInserted) {
              await _localDatabase.createTableForEveryUser(
                  userName: _connectedUserName);
            }
          }
        });
      }
    });

    if (mounted) {
      setState(() {
        this._isLoading = false;
      });
    }
  }

  /// Fetch Real Time Data From Cloud Firestore
  Future<void> _fetchRealTimeDataFromCloudStorage() async {
    final realTimeSnapshot =
        await this._cloudStoreDataManagement.fetchRealTimeDataFromFirestore();

    realTimeSnapshot!.listen((querySnapshot) {
      querySnapshot.docs.forEach((queryDocumentSnapshot) async {
        if (queryDocumentSnapshot.id ==
            FirebaseAuth.instance.currentUser!.email.toString()) {
          await _checkingForNewConnection(
              queryDocumentSnapshot, querySnapshot.docs);
        }
      });
    });
  }

  @override
  void initState() {
    _fetchRealTimeDataFromCloudStorage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(34, 48, 60, 1),
        floatingActionButton: _externalConnectionManagement(),
        body: LoadingOverlay(
          color: const Color.fromRGBO(0, 0, 0, 0.5),
          progressIndicator: const CircularProgressIndicator(
            backgroundColor: Colors.black87,
          ),
          isLoading: this._isLoading,
          child: ListView(
            children: [
              _activityList(context),
              _connectionList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: 20.0,
        left: 10.0,
      ),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).orientation == Orientation.portrait
          ? MediaQuery.of(context).size.height * (1.5 / 8)
          : MediaQuery.of(context).size.height * (3 / 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // Make ListView Horizontally
        itemCount: _allUserConnectionActivity.length,
        itemBuilder: (context, position) {
          return _activityCollectionList(context, position);
        },
      ),
    );
  }

  Widget _activityCollectionList(BuildContext context, int index) {
    return Container(
      margin: EdgeInsets.only(right: MediaQuery.of(context).size.width / 18),
      padding: EdgeInsets.only(top: 3.0),
      height: MediaQuery.of(context).size.height * (1.5 / 8),
      child: Column(
        children: [
          Stack(
            children: [
              if (_allUserConnectionActivity[index]
                  .contains('[[[new_activity]]]'))
                Container(
                  height:
                      MediaQuery.of(context).orientation == Orientation.portrait
                          ? (MediaQuery.of(context).size.height *
                                  (1.2 / 7.95) /
                                  2.5) *
                              2
                          : (MediaQuery.of(context).size.height *
                                  (2.5 / 7.95) /
                                  2.5) *
                              2,
                  width:
                      MediaQuery.of(context).orientation == Orientation.portrait
                          ? (MediaQuery.of(context).size.height *
                                  (1.2 / 7.95) /
                                  2.5) *
                              2
                          : (MediaQuery.of(context).size.height *
                                  (2.5 / 7.95) /
                                  2.5) *
                              2,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                    value: 1.0,
                  ),
                ),
              OpenContainer(
                closedColor: const Color.fromRGBO(34, 48, 60, 1),
                openColor: const Color.fromRGBO(34, 48, 60, 1),
                middleColor: const Color.fromRGBO(34, 48, 60, 1),
                closedElevation: 0.0,
                closedShape: CircleBorder(),
                transitionDuration: Duration(
                  milliseconds: 500,
                ),
                transitionType: ContainerTransitionType.fadeThrough,
                openBuilder: (context, openWidget) {
                  return Center();
                },
                closedBuilder: (context, closeWidget) {
                  return CircleAvatar(
                    backgroundColor: const Color.fromRGBO(34, 48, 60, 1),
                    backgroundImage:
                        ExactAssetImage('assets/images/google.png'),
                    radius: MediaQuery.of(context).orientation ==
                            Orientation.portrait
                        ? MediaQuery.of(context).size.height * (1.2 / 8) / 2.5
                        : MediaQuery.of(context).size.height * (2.5 / 8) / 2.5,
                  );
                },
              ),
              index == 0 // This is for current user Account
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? MediaQuery.of(context).size.height * (0.7 / 8) -
                                10
                            : MediaQuery.of(context).size.height * (1.5 / 8) -
                                10,
                        left: MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            ? MediaQuery.of(context).size.width / 3 - 65
                            : MediaQuery.of(context).size.width / 8 - 15,
                      ),
                      child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.lightBlue,
                          ),
                          child: GestureDetector(
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: MediaQuery.of(context).orientation ==
                                      Orientation.portrait
                                  ? MediaQuery.of(context).size.height *
                                      (1.3 / 8) /
                                      2.5 *
                                      (3.5 / 6)
                                  : MediaQuery.of(context).size.height *
                                      (1.3 / 8) /
                                      2,
                            ),
                          )),
                    )
                  : const SizedBox(),
            ],
          ),
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(
              top: 7.0,
            ),
            child: Text(
              'Generation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectionList(BuildContext context) {
    return LoadingOverlay(
      isLoading: this._isLoading,
      child: Container(
        margin: EdgeInsets.only(
            top: MediaQuery.of(context).orientation == Orientation.portrait
                ? 5.0
                : 0.0),
        padding: const EdgeInsets.only(top: 18.0, bottom: 30.0),
        height: MediaQuery.of(context).size.height * (5.15 / 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(31, 51, 71, 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10.0,
              spreadRadius: 0.0,
              offset: const Offset(0.0, -5.0), // shadow direction: bottom right
            )
          ],
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40.0), topRight: Radius.circular(40.0)),
          border: Border.all(
            color: Colors.black26,
            width: 1.0,
          ),
        ),
        child: ReorderableListView.builder(
          onReorder: (first, last) {
            // if (mounted) {
            //   setState(() {
            //     final String _draggableConnection =
            //     this._allConnectionsUserName.removeAt(first);
            //
            //     this._allConnectionsUserName.insert(
            //         last >= this._allConnectionsUserName.length
            //             ? this._allConnectionsUserName.length
            //             : last > first
            //             ? --last
            //             : last,
            //         _draggableConnection);
            //   });
            // }
          },
          itemCount: _allConnectionsUserName.length,
          itemBuilder: (context, position) {
            return chatTileContainer(
                context, position, _allConnectionsUserName[position]);
          },
        ),
      ),
    );
  }

  Widget chatTileContainer(BuildContext context, int index, String _userName) {
    return Card(
        key: Key('$index'),
        elevation: 0.0,
        color: const Color.fromRGBO(31, 51, 71, 1),
        child: Container(
          //padding: EdgeInsets.only(left: 1.0, right: 1.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0.0,
              primary: Color.fromRGBO(31, 51, 71, 1),
              onPrimary: Colors.lightBlueAccent,
            ),
            onPressed: () {
              print("Chat List Pressed");
            },
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: 5.0,
                    bottom: 5.0,
                  ),
                  child: OpenContainer(
                    closedColor: const Color.fromRGBO(31, 51, 71, 1),
                    openColor: const Color.fromRGBO(31, 51, 71, 1),
                    middleColor: const Color.fromRGBO(31, 51, 71, 1),
                    closedShape: CircleBorder(),
                    closedElevation: 0.0,
                    transitionDuration: Duration(milliseconds: 500),
                    transitionType: ContainerTransitionType.fadeThrough,
                    openBuilder: (_, __) {
                      return Center();
                    },
                    closedBuilder: (_, __) {
                      return CircleAvatar(
                        radius: 30.0,
                        backgroundColor: const Color.fromRGBO(31, 51, 71, 1),
                        backgroundImage:
                            ExactAssetImage('assets/images/google.png'),
                        //getProperImageProviderForConnectionsCollection(
                        //    _userName),
                      );
                    },
                  ),
                ),
                OpenContainer(
                  closedColor: const Color.fromRGBO(31, 51, 71, 1),
                  openColor: const Color.fromRGBO(31, 51, 71, 1),
                  middleColor: const Color.fromRGBO(31, 51, 71, 1),
                  closedElevation: 0.0,
                  openElevation: 0.0,
                  transitionDuration: Duration(milliseconds: 500),
                  transitionType: ContainerTransitionType.fadeThrough,
                  openBuilder: (context, openWidget) {
                    return ChatScreen(
                      userName: _userName,
                    );
                  },
                  closedBuilder: (context, closeWidget) {
                    return Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width / 2 + 30,
                      padding: EdgeInsets.only(
                        top: 5.0,
                        bottom: 5.0,
                        left: 5.0,
                      ),
                      child: Column(
                        children: [
                          Text(
                            _userName.length <= 18
                                ? _userName
                                : '${_userName.replaceRange(18, _userName.length, '...')}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            height: 12.0,
                          ),

                          /// For Extract latest Conversation Message
//                          _latestDataForConnectionExtractPerfectly(_userName)
                          Text(
                            'Hello Sam',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(
                      top: 2.0,
                      bottom: 2.0,
                    ),
                    child: Column(
                      children: [
                        Text('12:00'),
                        SizedBox(
                          height: 10.0,
                        ),
                        Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _externalConnectionManagement() {
    return OpenContainer(
      closedColor: const Color.fromRGBO(20, 200, 50, 1),
      middleColor: const Color.fromRGBO(34, 48, 60, 1),
      openColor: const Color.fromRGBO(34, 48, 60, 1),
      closedShape: CircleBorder(),
      closedElevation: 15.0,
      transitionDuration: Duration(
        milliseconds: 500,
      ),
      transitionType: ContainerTransitionType.fadeThrough,
      openBuilder: (_, __) {
        return SearchScreen();
      },
      closedBuilder: (_, __) {
        return Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 37.0,
          ),
        );
      },
    );
  }
}
