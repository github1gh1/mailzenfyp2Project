import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mailzen/databases/liveDatabase.dart';
import 'package:mailzen/entities/Message_log.dart';
import 'package:mailzen/globals.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../entities/Account.dart';
//import '../entities/Folder.dart';
import '../entities/Rule.dart';
import '../entities/folder.dart';
import '../entities/message.dart';

class SqliteDatabaseHelper {
  //late final Account account;
  final String _tableName = "Message";
  final String _AcctableName = "Account";
 final String _ftableName = "Folder";


Future<int> getInboxId(int id) async {
   Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM  Folder where ACC_ID=${id}");
    return maps.isNotEmpty ? maps[0]["f_id"] : 0; 
}

Future<void> initDB() async {
    String newPath = join(await getDatabasesPath(), "Mailzen.db");
    final exists = await databaseExists(newPath);
    if (!exists) {
        try {
          
            const path = 'assets/Mailzen.db';
            File(path).copySync(newPath);
        } catch (_) {}
     }
}



  Future<Database> getDataBase() async {
    initDB();
    return openDatabase(
      join(await getDatabasesPath(), "Mailzen.db"),
      onCreate: (db, version) async {
        // await db.execute(
        //   "CREATE TABLE $_tableName (id TEXT PRIMARY KEY, name TEXT, imageUrl TEXT)",
        // );
      },
      version: 1,
    );
  }
  Future<int> insertMessage(Message msg) async {
    int msgId = 1;
    Database db = await getDataBase();
    await db.insert( _tableName, msg.toMap()).then((value) {
      msgId = value;
    });
    return msgId;
  }

Future<int> insertMessageAndGetId(Message message) async {
   Database db = await getDataBase();
   if(await getMessageByMsgID(message.MsgID)==null)
  {int insertedId = await db.insert('message', message.toMap());
  return insertedId;
  }
  else
  return 0;
}

 Future<Message?> getMessageByMsgID(String msgId) async {
    Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM  Message where msgId='$msgId'");
    
  if (maps.isNotEmpty) {
    return Message.fromMap(maps[0]);
  } else {
    // Handle the case when no message is found, return null or throw an exception.
    return null;
  }
    
    }
  

Future<bool> getFolder(String name,int accid) async {
    Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM  Folder where F_Name='$name' and ACC_ID=$accid");
    
  if (maps.isNotEmpty) {
    return true;
  } else {
    // Handle the case when no message is found, return null or throw an exception.
    return false;
  }
    
    }
  
Future<bool> moveMessageByFolderName(int id,int accId,String folderName) async {
    Database db = await getDataBase();
   await db.rawQuery("update Message set F_Id=(select F_ID from Folder where ACC_ID= $accId and  lower(F_Name) = '$folderName') where M_ID=$id");
  return true;
  }

Future<bool> moveMessage(int id,int folderId) async {
    Database db = await getDataBase();
    print("update Message set F_Id=$folderId where M_ID=$id");
   await db.rawQuery("update Message set F_Id=$folderId where M_ID=$id");
  return true;
  }

Future<int> DeleteMessageFromDatabase(var messageid) async {
  print("msg id:${messageid}");
  final db = await getDataBase();
  return await db.delete(
    'Message',
    where: 'M_ID = ?',
    whereArgs: [messageid],
  );
}


  Future<List<Message>> getAllMessages(int accountId,int folderId) async {
    Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT Message.* FROM FOLDER CROSS JOIN ACCOUNT CROSS join Message WHERE FOLDER.ACC_ID = $accountId AND Folder.ACC_ID=ACCOUNT.[ACC_ID] AND FOLDER.F_ID='$folderId' and Folder.F_ID = Message.F_ID  ORDER BY Message.Receiving_Date_Time desc");
  print(maps.length);
    return List.generate(maps.length, (index) {
      return  Message(
        
           M_ID: maps[index]['M_ID'],
          Subject: maps[index]['Subject'],
        Sender: maps[index]['Sender'],
        Receiving_Date_Time: maps[index]['Receiving_Date_Time'],
        body: maps[index]['body'],
       Action: maps[index]['Action'],
       F_ID: maps[index]['F_ID'],
        Ordinal: maps.length - index-1,
        MsgID: maps[index]['MsgID'],
        IsAttachment: maps[index]['IsAttachment'],
       isStarred : false, 
      
        );
     
    //    return msg;
    });
    
  }


    Future<List<Message>> getAllInbox()async{
     Database db = await getDataBase();
  String sqlQuery = "select m.* from Message m join Folder f on m.F_ID=f.F_ID where f.F_Name = 'INBOX'";
  List<Map<String, dynamic>> maps = await db.rawQuery(sqlQuery);
  print("SQL Query: $sqlQuery"); 
  return List.generate(maps.length, (index) {
    
      return  Message(
        
           M_ID: maps[index]['M_ID'],
          Subject: maps[index]['Subject'],
        Sender: maps[index]['Sender'],
        Receiving_Date_Time: maps[index]['Receiving_Date_Time'],
        body: maps[index]['body'],
       Action: maps[index]['Action'],
       F_ID: maps[index]['F_ID'],
         Ordinal: maps[index]['Ordinal'],
         MsgID: maps[index]['MsgID'],
         IsAttachment: maps[index]['IsAttachment'],
       isStarred : false, 
     
        );
     
    //    return msg;
    });
  }
  
// Add this method to your SqliteDatabaseHelper class
Future<String> getAccountNameById(int accountId) async {
  Database db = await getDataBase();
  List<Map<String, dynamic>> maps = await db.rawQuery("SELECT UserName FROM Account WHERE ACC_ID = $accountId");
  
  if (maps.isNotEmpty) {
    return maps.first['UserName'] ?? ''; // Replace 'UserName' with the actual field name for the account name
  } else {
    return ''; // Return an empty string or handle the case when the account is not found
  }
}

  //for account
   Future<int> insertAccount(Account acc) async {
    int accId = 0;
    Database db = await getDataBase();
    await db.insert( _AcctableName, acc.toMap()).then((value) {
     accId = value;
    });
    return accId;
  }

   Future<List<Account>> getAllAccounts() async {
    Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM  Account");
    return List.generate(maps.length, (index) {
      // print(maps[index]['ACC_ID']);
      // print(maps[index]['Token']);

      return  Account(
           acc_id: maps[index]['ACC_ID'],
        username: maps[index]['UserName'],
        acc_type: maps[index]['ACC_Type'],
        displayname: maps[index]['DisplayName'],
        Token: maps[index]['Token'],
        );
    });
  }

  Future<Account> getAccount(String accId)async{
    Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM $_AcctableName ");
    if(maps.length == 1){
      return Account(
        acc_id: maps[0]['ACC_ID'],
        username: maps[0]['UserName'],
        acc_type: maps[0]['acc_type'],
        displayname: maps[0]['displayname'],
        Token: maps[0]['Token'],
       
        );
    } else {
       return Account(
        acc_id: 0,
        username: '',
        acc_type: '',
        displayname: '',
        Token: '',
       
        );
    }
  }


  //For Folder
   Future<int> insertFolder(Folder f) async {
    int fId = 0;
    Database db = await getDataBase();
    if(getFolder(f.F_Name,f.ACC_ID)!=true)
    {await db.insert( _ftableName, f.toMap()).then((value) {
      fId = value;
    });
    }
    return fId;
  }
  Future<List<Folder>> getAllFolders(int accountId) async {
    Database db = await getDataBase();
    var query = "SELECT * FROM Folder where ACC_ID=$accountId";
    if(accountId==0)
      query = "SELECT * FROM Folder ";
    List<Map<String, dynamic>> maps = await db.rawQuery(query);
    //print(maps[0]);
    List<Folder> folders = [];
    for (var map in maps) {
        // if(map['F_Name']=='All Mail') map['F_Name']="[Gmail]/:${map['F_Name']}";
        // if(map['F_Name']=='Drafts') map['F_Name']="[Gmail]/:${map['F_Name']}";
        // if(map['F_Name']=='Important') map['F_Name']="[Gmail]/:${map['F_Name']}";
        //  if(map['F_Name']=='Starred') map['F_Name']="[Gmail]/:${map['F_Name']}";
        //  if(map['F_Name']=='Sent Mail') map['F_Name']="[Gmail]/:${map['F_Name']}";
        //  if(map['F_Name']=='Spam') map['F_Name']="[Gmail]/:${map['F_Name']}";
        //  if(map['F_Name']=='Trash' && account!.acc_type!='yahoo') map['F_Name']="[Gmail]/:${map['F_Name']}";
        //  if(map['F_Name']=='Bin') map['F_Name']="[Gmail]/:${map['F_Name']}";
      folders.add(Folder.fromMap(map));
    }
return folders;
  }

  Future<Folder> getFolders()async{
    Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM Folder");
    if(maps.length == 1){
      return Folder(
        F_ID: maps[0]['F_ID'],
       F_Name: maps[0]['F_Name'],
         ACC_ID: maps[0]['ACC_ID'],
        Is_Deleted: maps[0]['Is_Deleted'],
        Parent_Id: maps[0][' Parent_Id'],
       count: 0
        );
    } else {
       return Folder(
        F_ID: 0,
       F_Name: '',
        ACC_ID: 0,
       Parent_Id: 0,
      Is_Deleted: 0,
      count: 0,
        );
    }
  }
Future<int> updateFolderName(int folderId, String newName) async {
  final db = await getDataBase();
  return await db.update(
    'Folder',
    {'F_Name': newName},
    where: 'F_ID = ?',
    whereArgs: [folderId],
  );
}

Future<int> DeleteFolderfFromDatabase(int folderId) async {
  final db = await getDataBase();
  return await db.delete(
    'Folder',
    where: 'F_ID = ?',
    whereArgs: [folderId],
  );
}

  Future<bool> FolderExists(int accountId,String name)async{
    Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM Folder where ACC_ID=$accountId and F_Name='${name}'");
    return maps.length == 1;
  }
Future<Folder> getFolderById(int folderId) async {
  Database db = await getDataBase();
  List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT * FROM Folder WHERE F_ID = $folderId");
  if (maps.isNotEmpty) {
    return Folder.fromMap(maps.first);
  } else {
    // Handle the case when the folder is not found
    return Folder(F_ID: 0, F_Name: '', ACC_ID: 0, Parent_Id: 0, Is_Deleted: 0, count: 0);
  }
}



//ADD RULE
  Future<int> addRule(Rule rule) async {
    int Id = 0;
    Database db = await getDataBase();
    await db.insert( "Rule", rule.toMap()).then((value) {
     Id = value;
    });
    return Id;
  }

  Future<List<Rule>> getAllRule() async {
    Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM  Rule");
    return List.generate(maps.length, (index) {
      // print(maps[index]['Rule_ID']);
      // print(maps[index]['Name']);
      // print(maps[index]['Field1']);

      var rule =  Rule(
         
        Name: maps[index]['Name'] ?? '',
        Field1:maps[index]['Field1'] ?? '',
        ReceivingAccount: maps[index]['ReceivingAccount'] ?? '',
        DestinationAccount: maps[index]['DestinationAccount'] ?? '',
        DestinationFolder: maps[index]['DestinationFolder'] ?? '',
        Status: maps[index]['Status'] ?? '',
        ApplyMode: maps[index]['ApplyMode'] ?? '',
        Field2:maps[index]['Field2'] ?? '',
        Field3:maps[index]['Field3'] ?? '',
        Value1:maps[index]['Value1'] ?? '',
        Value2:maps[index]['Value2'] ?? '',
        Value3:maps[index]['Value3'] ?? '',
        Attachment:maps[index]['Attachment'] ?? 0,
        );
        rule.Rule_ID = maps[index]['Rule_ID'];
        return rule;
    });
  }
Future<int> updateRule(Rule rule) async {
  final db = await getDataBase();
  return await db.update(
    'Rule',
    rule.toMap(),
    where: 'Rule_ID = ?',
    whereArgs: [rule.Rule_ID],
  );
}



  Future<Rule> getRules()async{
    Database db = await getDataBase();
    List<Map<String, dynamic>> maps = await db.rawQuery("SELECT * FROM Rule");
    if(maps.length == 1){
      var rule = Rule(
     
       Name: maps[0]['Name'],
         Field1: maps[0]['Field1'],
        ReceivingAccount: maps[0]['ReceivingAccount'],
        DestinationAccount: maps[0]['DestinationAccount'],
        DestinationFolder: maps[0]['DestinationFolder'],
        Status: maps[0]['Status'],  
        ApplyMode: maps[0]['ApplyMode'], 
        Field2:maps[0]['Field2'], 
        Field3:maps[0]['Field3'], 
        Value1:maps[0]['Value1'], 
        Value2:maps[0]['Value2'], 
        Value3:maps[0]['Value3'], 
        Attachment:maps[0]['Attachment'], 
        );

       rule.Rule_ID = maps[0]['Rule_ID'];
        return rule;
    } else {
       return Rule(
       // Rule_ID: 0,
       Name: '',
        Field1: '',
      ReceivingAccount: '',
      DestinationAccount: '',
      DestinationFolder: '',
      Status: 0,
      ApplyMode: 0,
      Field2:'',
      Field3:'',
      Value1: '',
      Value2: '',
      Value3: '',
      Attachment:0
        );
    }
    
  }

    //execute Rule after every 5 seconds
 static void startTimer() {
  // Set up a timer for 5 seconds
  SqliteDatabaseHelper db = SqliteDatabaseHelper();
  Timer.periodic(Duration(seconds: 10), (_) async {
    // This function will be called after 5 seconds
   List<Rule> rules = await db.getAllRule();
    for (var rule in rules) {
      if(rule.Status==1)
        db.ExecuteRule(rule.ruleID); 
          //LiveServer.moveMailWithAccount("mailzen118@gmail.com", "sqmapixekwwchsie", 'INBOX', message['Ordinal'], rule.DestinationFolder);
          
    }
   
  });
}
//add message_log

 Future<int> AddMessageLog(Messagelog messagelog) async {
    int Id = 0;
    Database db = await getDataBase();

    await db.insert( "Messagelog", messagelog.toMap()).then((value) {
     Id = value;
    });
    return Id;
  }

 

  //execute Rule
  Future<bool> ExecuteRule(int? ruleId) async{
    final db = await getDataBase();

    //1. First Load the Rule Detail
   List<Map> maps = await db.query("Rule",columns:['*'],where:"Rule_ID=?",whereArgs:[ruleId]);
   if(maps.length==0)
    return false;
  
  var rule = Rule(
       Name: maps[0]['Name'] ?? '',
        Field1:maps[0]['Field1'] ?? '',
        ReceivingAccount: maps[0]['ReceivingAccount'] ?? '',
        DestinationAccount: maps[0]['DestinationAccount'] ?? '',
        DestinationFolder: maps[0]['DestinationFolder'] ?? '',
        Status: maps[0]['Status'] ?? '',
        ApplyMode: maps[0]['ApplyMode'] ?? '',
        Field2:maps[0]['Field2'] ?? '',
        Field3:maps[0]['Field3'] ?? '',
        Value1:maps[0]['Value1'] ?? '',
        Value2:maps[0]['Value2'] ?? '',
        Value3:maps[0]['Value3'] ?? '',
        Attachment:maps[0]['Attachment'] ?? 0,
        );
        rule.Rule_ID = maps[0]['Rule_ID'];



      var fromValue = "";
      var subjectValue = "";
      var bodyValue = "";

    if(rule.Field1=="From")fromValue = rule.Value1;
    if(rule.Field1=="Subject")subjectValue = rule.Value1;
    if(rule.Field1=="Body")bodyValue = rule.Value1;

    if(rule.Field2=="From")fromValue = rule.Value2;
    if(rule.Field2=="Subject")subjectValue = rule.Value2;
    if(rule.Field2=="Body")bodyValue = rule.Value2;

    if(rule.Field3=="From")fromValue = rule.Value3;
    if(rule.Field3=="Subject")subjectValue = rule.Value3;
    if(rule.Field3=="Body")bodyValue = rule.Value3;



    //2. First Load Receiving Account Inbox
   var query = "SELECT m.* FROM Account a JOIN (SELECT * FROM Folder f WHERE F_Name = 'Inbox') f on a.[ACC_ID]=f.ACC_ID JOIN Message m on m.F_ID=f.F_ID WHERE a.UserName='${rule.ReceivingAccount}'";

    if (rule.Field1 != '') {
      // if (rule.NotSender==true)
      // query += " AND m.Sender NOT LIKE '%$fromValue%'";
      // else
      query += " AND m.Sender LIKE '%$fromValue%'";
      
    }
    if (rule.Field2 != '') {
      query += " AND m.Subject LIKE '%$subjectValue%'";
    }
    if (rule.Field3 != '') {
      query += " AND m.Body LIKE '%$bodyValue%'";
    }


  //3. Get destination account folder id
  var sql = "select * from Folder f JOIN Account a on a.[ACC_ID]=f.ACC_ID where a.UserName='${rule.DestinationAccount}' AND f.F_Name='${rule.DestinationFolder}'";
  List<Map<String,dynamic>> result = await db.rawQuery(sql);
if(result.length==0)
    return false;
  var folderId = result[0]["F_ID"];
  // print("FolderID");
  // print(folderId);
    

    // print("Query: $query"); 
    List<Map<String, dynamic>> inboxMessages =  await db.rawQuery(query);
    // print(inboxMessages.length);
    for (var message in inboxMessages) {
      
          var query1 = "update Message set F_ID=$folderId where M_ID=${message['M_ID']}";

     print("Query: $query1"); 
          //live move call.
          
          var messageLog = Messagelog(
            M_ID: message["M_ID"],
            OlderFolderId: message['F_ID'],
            CurrentFolderId: folderId,
            ActionType: 'Move',
            LiveSync: 0
          );
          // print("Update Query:"+query1);
          // print(messageLog);
          await db.rawUpdate(query1);
          LiveServer.moveMailWithAccount(account!.username, account!.Token, folderName, message['Ordinal'], rule.DestinationFolder);
          
          AddMessageLog(messageLog);
         
    }
return true;

  }

// If Attachment is true:

// It constructs a rule based on certain conditions related to the sender, subject, and body of the email.
// It loads messages from the "Inbox" of the receiving account that match the specified conditions.
// It retrieves the destination folder ID based on the rule's destination account and folder.
// It then updates the messages' folder ID to move them to the specified destination folder.
// If Attachment is false:

// It constructs a similar rule but processes emails without attachments.
// So, when you check the Attachment checkbox, the rule will move emails with attachments, and when you don't check it, the rule will apply to emails without attachments.


}


