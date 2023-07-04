import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import "filters.dart";

// String which indicates a base database file. This file is necessary in case
// you are looking to approve new data without having uploaded a database file.
String dataLocation = "Database.csv";

// Stores the raw data of the uploaded database, used when updating the database
// before downloading the new database with newly approved entries
List<List<dynamic>> rawData = [];

// Stores all of the processed internship data
List<Internship> internships = [];

// Stores all of the internship objects with the filters applied
List<Internship> filteredInternships = [];

// Start year for the filter timeline slider
int startYear = 2021;

// Stores the data that needs to be approved
List<List<dynamic>> incomingData = [];

// Stores the data that has been approved and is ready to be downloaded
List<List<dynamic>> acceptedEntries = [];

// The latest ID in the database
int latestId = 0;

// Internship object under which all internships are stored
class Internship {
  late int internshipID;
  late String studentName; // private
  late String engineeringConcentration; // public
  late String contactable; // private
  late String studentPhone; // private
  late String studentEmail; // private
  late String jobTitle; // public
  late String companyName; // public
  late String timeline; // public
  late String compensation; // public
  late String type; // public
  late String companyAddress; // public
  late String companyPhone; // private
  late String companyEmail; // private
  late String location; // map view only
  late int startYear;
  late int endYear;

  Internship(
    this.internshipID,
    this.studentName,
    this.engineeringConcentration,
    this.contactable,
    this.studentPhone,
    this.studentEmail,
    this.jobTitle,
    this.companyName,
    this.timeline,
    this.compensation,
    this.type,
    this.companyAddress,
    this.companyPhone,
    this.companyEmail,
    this.location,
    this.startYear,
    this.endYear,
  );
}

// Turns a string indicating a quarter into an interger for the timeline slider
int quarterStringToInt(String quarter) {
  // Makes the string lowercase for resiliency with random capitilization
  quarter = quarter.toLowerCase();
  if (quarter == 'winter') {
    return 0;
  }
  if (quarter == 'spring') {
    return 1;
  }
  if (quarter == 'summer') {
    return 2;
  }
  if (quarter == 'fall') {
    return 3;
  }
  return 0;
}

// Processes a database file into a a list of internship objects
Future<void> establishInternships(String dataLocation) async {
  // ask for database file
  rawData = await importData(dataLocation);

  // remove the header
  if (rawData.isNotEmpty) {
    rawData.removeAt(0);
  }

  // This code gets the minimum and maximum recorded year in the database
  for (var internship in rawData) {
    // get the timeline of the internship
    var timeline = internship[8];
    // Processes the timeline string into a number for use in the timeline filter
    var extractedInts = timeline.replaceAll(RegExp(r'[^0-9]'), '');

    var internshipStartYear = int.parse(extractedInts.substring(0, 4));
    var internshipEndYear = int.parse(extractedInts.substring(4, 8));

    var dividedQuarter = timeline.split(' - ');
    // Starting Quarter
    var firstQuarterString = dividedQuarter[0].replaceAll(RegExp(r'[0-9]'), '');
    firstQuarterString = firstQuarterString.replaceAll(' ', '');

    // Ending Quarter
    var secondQuarterString =
        dividedQuarter[1].replaceAll(RegExp(r'[0-9]'), '');
    secondQuarterString = secondQuarterString.replaceAll(' ', '');

    var firstQuarter = quarterStringToInt(firstQuarterString);
    var secondQuarter = quarterStringToInt(secondQuarterString);

    // Finalizes the integer to be used in the timeline filter
    var startDivision = (internshipStartYear - startYear) * 4 + firstQuarter;
    var endDivision = (internshipEndYear - startYear) * 4 + secondQuarter;

    // Create the internship object from the entry and add it to the
    // internships list
    internships.add(
      Internship(
        internship[0],
        internship[1].toString().trim(),
        internship[2].toString().trim(),
        internship[3].toString().trim(),
        internship[4].toString().trim(),
        internship[5].toString().trim(),
        internship[6].toString().trim(),
        internship[7].toString().trim(),
        internship[8].toString().trim(),
        internship[9].toString().trim(),
        internship[10].toString().trim(),
        internship[11].toString().trim(),
        internship[12].toString().trim(),
        internship[13].toString().trim(),
        internship[14].toString().trim(),
        startDivision,
        endDivision,
      ),
    );
  }
}

// Filters the internship list based on the filters applied
void filterInternships() {
  // Start with a blank list
  List<Internship> filteredList = [];

  for (var internship in internships) {
    // Assume an internship is going to pass and check for filters that could
    // prove this assumption wrong
    bool pass = true;
    // Check for the concentration
    if (filters.concentration != 'All' &&
        filters.concentration != internship.engineeringConcentration) {
      pass = false;
    }
    // Check for the type (on-site or remote)
    if (filters.onsite == false && internship.type == 'On-Site') {
      pass = false;
    }
    if (filters.remote == false && internship.type == 'Remote') {
      pass = false;
    }
    // Check for the compensation
    if (filters.paid == false && internship.compensation == 'Paid') {
      pass = false;
    }
    if (filters.unpaid == false && internship.compensation == 'Unpaid') {
      pass = false;
    }
    // Check for the timeline match
    if (filters.startYear > internship.endYear ||
        filters.endYear < internship.startYear) {
      pass = false;
    }

    // If the internship passed the checks, add it to the filtered list
    // to display
    if (pass) {
      filteredList.add(internship);
    }
  }
  // Update the official list of filtered internships
  filteredInternships = filteredList;
}

// Import data from a CSV file
Future<List<List>> importData(String dataLocation) async {
  rawData = [];
  // Promt the user for a file, assumed to be a csv file
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  // Turn the csv file into a list of lists
  if (result != null) {
    final bytes = result.files.first.bytes!;
    final rawString = utf8.decode(bytes);

    rawData = const CsvToListConverter().convert(rawString);
    // Update the latest ID based on the last entry
    latestId = rawData.last[0];
    return rawData;
  } else {
    return [];
  }
}
