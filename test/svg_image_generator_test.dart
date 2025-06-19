import 'package:flutter_test/flutter_test.dart';
import 'package:nhb_results_app/match.dart';
import 'package:nhb_results_app/svg_image_generator.dart';
import 'package:xml/xml.dart';

void main() {
  group('SvgImageGenerator.replaceSvgTextElements', () {
    test('should replace date and match data in SVG content', () {
      // Arrange
      final testSvgString = '''
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape">
        <text inkscape:label="date" style="font-size:40px">
          <tspan style="font-weight:bold;fill:#ffffff;font-style:normal">Default Date</tspan>
        </text>
        <text inkscape:label="match1-team1" style="font-size:40px">
          <tspan>Default Team 1</tspan>
        </text>
        <text inkscape:label="match1-team2" style="font-size:40px">
          <tspan style="font-weight:normal;font-style:italic">Default Team 2</tspan>
        </text>
        <text inkscape:label="match1-score1" style="font-size:40px">
          <tspan style="fill:#ffffff;font-weight:bold">0</tspan>
        </text>
        <text inkscape:label="match1-score2" style="font-size:40px">
          <tspan style="fill:#ffffff;font-size:36px">0</tspan>
        </text>
      </svg>
      ''';
      
      final testMatches = [
        Match(
          date: "Test Date",
          place: "Test Place",
          level: "Test Level",
          team1: "NHB Team",
          team2: "Opponent Team",
          score1: "25",
          score2: "20",
        ),
      ];
      
      // Expected values based on Match class methods
      final expectedTeam1 = "NHB Team Test Level"; // fullTeam1() adds level to NHB teams
      final expectedTeam2 = "Opponent Team"; // fullTeam2() doesn't add level to non-NHB teams
      
      // Act
      final result = SvgImageGenerator.replaceSvgTextElements(testSvgString, testMatches);
      
      // Assert
      expect(result, contains('Test Date'));
      expect(result, contains(expectedTeam1));
      expect(result, contains(expectedTeam2));
      expect(result, contains('25'));
      expect(result, contains('20'));
      
      // Check that the NHB team color was updated
      expect(result, contains('fill:#e0038c'));
      
      // Parse the result to verify structure
      final document = XmlDocument.parse(result);
      final dateElement = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'date');
      final team1Element = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match1-team1');
      final team2Element = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match1-team2');
      final score1Element = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match1-score1');
      final score2Element = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match1-score2');
      
      expect(dateElement.findElements('tspan').first.innerText, equals('Test Date'));
      expect(team1Element.findElements('tspan').first.innerText, equals(expectedTeam1));
      expect(team2Element.findElements('tspan').first.innerText, equals(expectedTeam2));
      expect(score1Element.findElements('tspan').first.innerText, equals('25'));
      expect(score2Element.findElements('tspan').first.innerText, equals('20'));
      
      // Verify color changes - now applied to tspan elements
      expect(team1Element.findElements('tspan').first.getAttribute('style'), contains('fill:#e0038c'));
      expect(team2Element.findElements('tspan').first.getAttribute('style'), contains('fill:#ffffff'));
    });

    test('should handle multiple matches correctly', () {
      // Arrange
      final testSvgString = '''
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape">
        <text inkscape:label="date" style="font-size:40px">
          <tspan style="font-weight:bold;fill:#ffffff;font-style:normal">Default Date</tspan>
        </text>
        <text inkscape:label="match1-team1" style="font-size:40px">
          <tspan style="font-weight:bold;fill:#ffffff;text-anchor:middle">Default Team 1-1</tspan>
        </text>
        <text inkscape:label="match1-team2" style="font-size:40px">
          <tspan style="font-weight:normal;fill:#ffffff;font-style:italic">Default Team 1-2</tspan>
        </text>
        <text inkscape:label="match2-team1" style="font-size:40px">
          <tspan style="fill:#ffffff;font-weight:bold">Default Team 2-1</tspan>
        </text>
        <text inkscape:label="match2-team2" style="font-size:40px">
          <tspan style="font-size:36px;fill:#ffffff">Default Team 2-2</tspan>
        </text>
      </svg>
      ''';
      
      final testMatches = [
        Match(
          date: "Test Date 1",
          place: "Test Place 1",
          level: "Test Level 1",
          team1: "NHB Team 1",
          team2: "Opponent 1",
          score1: "25",
          score2: "20",
        ),
        Match(
          date: "Test Date 2",
          place: "Test Place 2",
          level: "Test Level 2",
          team1: "Team 2",
          team2: "NHB Team 2",
          score1: "18",
          score2: "22",
        ),
      ];
      
      // Expected values
      final expectedTeam1Match1 = "NHB Team 1 Test Level 1";
      final expectedTeam2Match1 = "Opponent 1";
      final expectedTeam1Match2 = "Team 2";
      final expectedTeam2Match2 = "NHB Team 2 Test Level 2";
      
      // Act
      final result = SvgImageGenerator.replaceSvgTextElements(testSvgString, testMatches);
      
      // Assert
      // Parse the result to verify structure
      final document = XmlDocument.parse(result);
      
      // Check first match
      final team1Match1Element = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match1-team1');
      final team2Match1Element = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match1-team2');
      
      expect(team1Match1Element.findElements('tspan').first.innerText, equals(expectedTeam1Match1));
      expect(team2Match1Element.findElements('tspan').first.innerText, equals(expectedTeam2Match1));
      expect(team1Match1Element.findElements('tspan').first.getAttribute('style'), contains('fill:#e0038c'));
      
      // Check second match
      final team1Match2Element = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match2-team1');
      final team2Match2Element = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match2-team2');
      
      expect(team1Match2Element.findElements('tspan').first.innerText, equals(expectedTeam1Match2));
      expect(team2Match2Element.findElements('tspan').first.innerText, equals(expectedTeam2Match2));
      expect(team2Match2Element.findElements('tspan').first.getAttribute('style'), contains('fill:#e0038c'));
    });

    test('should handle empty match list gracefully', () {
      // Arrange
      final testSvgString = '''
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape">
        <text inkscape:label="date" style="font-size:40px">
          <tspan style="font-weight:bold;fill:#ffffff;font-style:normal">Default Date</tspan>
        </text>
        <text inkscape:label="match1-team1" style="font-size:40px">
          <tspan style="font-weight:bold;fill:#ffffff;text-anchor:middle">Default Team 1</tspan>
        </text>
      </svg>
      ''';
      
      final emptyMatches = <Match>[];
      
      // Act
      final result = SvgImageGenerator.replaceSvgTextElements(testSvgString, emptyMatches);
      
      // Assert
      // The original SVG should be returned unchanged
      final document = XmlDocument.parse(result);
      final dateElement = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'date');
      final team1Element = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match1-team1');
      
      expect(dateElement.findElements('tspan').first.innerText, equals('Default Date'));
      expect(team1Element.findElements('tspan').first.innerText, equals('Default Team 1'));
    });

    test('should handle invalid SVG content gracefully', () {
      // Arrange
      final invalidSvgString = '''
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape">
        <text inkscape:label="date" style="font-size:40px">
          <tspan style="font-weight:bold;fill:#ffffff;font-style:normal">Default Date</tspan>
        </text>
        <text inkscape:label="match1-team1" style="font-size:40px">
          <tspan style="font-weight:bold;fill:#ffffff;text-anchor:middle">Default Team 1</tspan>
        </text>
      '''; // Missing closing tag
      
      final testMatches = [
        Match(
          date: "Test Date",
          place: "Test Place",
          level: "Test Level",
          team1: "NHB Team",
          team2: "Opponent Team",
          score1: "25",
          score2: "20",
        ),
      ];
      
      // Expected values
      final expectedTeam1 = "NHB Team Test Level";
      
      // Act
      final result = SvgImageGenerator.replaceSvgTextElements(invalidSvgString, testMatches);
      
      // Assert
      // The original SVG should be returned unchanged
      expect(result, equals(invalidSvgString));
    });

    test('should handle match index out of bounds gracefully', () {
      // Arrange
      final testSvgString = '''
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape">
        <text inkscape:label="match3-team1" style="font-size:40px">
          <tspan style="font-weight:bold;fill:#ffffff;text-anchor:middle">Default Team 3-1</tspan>
        </text>
      </svg>
      ''';
      
      final testMatches = [
        Match(
          date: "Test Date",
          place: "Test Place",
          level: "Test Level",
          team1: "NHB Team",
          team2: "Opponent Team",
          score1: "25",
          score2: "20",
        ),
      ];
      
      // Expected values
      final expectedTeam1 = "NHB Team Test Level";
      
      // Act
      final result = SvgImageGenerator.replaceSvgTextElements(testSvgString, testMatches);
      
      // Assert
      // The match3 elements should remain unchanged since we only have 1 match (index out of bounds)
      final document = XmlDocument.parse(result);
      final team1Element = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match3-team1');
      
      expect(team1Element.findElements('tspan').first.innerText, equals('Default Team 3-1'));
    });

    test('should handle malformed label attributes gracefully', () {
      // Arrange
      final testSvgString = '''
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape">
        <text inkscape:label="match1" style="font-size:40px">
          <tspan style="font-weight:bold;fill:#ffffff;font-style:normal">Default Team 1</tspan>
        </text>
        <text inkscape:label="match1-invalid" style="font-size:40px">
          <tspan style="font-weight:normal;fill:#ffffff;font-style:italic">Invalid Field</tspan>
        </text>
      </svg>
      ''';
      
      final testMatches = [
        Match(
          date: "Test Date",
          place: "Test Place",
          level: "Test Level",
          team1: "NHB Team",
          team2: "Opponent Team",
          score1: "25",
          score2: "20",
        ),
      ];
      
      // Expected values
      final expectedTeam1 = "NHB Team Test Level";
      
      // Act
      final result = SvgImageGenerator.replaceSvgTextElements(testSvgString, testMatches);
      
      // Assert
      // Elements with malformed labels should remain unchanged
      final document = XmlDocument.parse(result);
      final malformedElement1 = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match1');
      final malformedElement2 = document.findAllElements('text')
          .firstWhere((element) => element.getAttribute('inkscape:label') == 'match1-invalid');
      
      expect(malformedElement1.findElements('tspan').first.innerText, equals('Default Team 1'));
      expect(malformedElement2.findElements('tspan').first.innerText, equals('Invalid Field'));
    });

    test('should handle elements without tspan gracefully', () {
      // Arrange
      final testSvgString = '''
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape">
        <text inkscape:label="match1-team1" style="font-size:40px;font-weight:bold">
          Text without tspan
        </text>
      </svg>
      ''';
      
      final testMatches = [
        Match(
          date: "Test Date",
          place: "Test Place",
          level: "Test Level",
          team1: "NHB Team",
          team2: "Opponent Team",
          score1: "25",
          score2: "20",
        ),
      ];
      
      // Expected values
      final expectedTeam1 = "NHB Team Test Level";
      
      // Act
      final result = SvgImageGenerator.replaceSvgTextElements(testSvgString, testMatches);
      
      // Assert
      // The method should not crash when encountering text elements without tspan
      expect(result, isNotNull);
      expect(result, isA<String>());
    });
  });
}