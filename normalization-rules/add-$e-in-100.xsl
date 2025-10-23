<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <xsl:mode on-no-match="shallow-copy"/>
  
  <!-- Variable to hold the external document -->
  <xsl:variable name="external-data" as="document-node()?" select="document('https://raw.githubusercontent.com/yalelibrary-metadata-services/alma_rules_testing/refs/heads/main/normalization_lookup/rel_designator.xml')"/>
  <xsl:template match="datafield[@tag='100']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <!-- $a string -->
      <xsl:variable name="a" select="normalize-space(string(subfield[@code='a'][1]))"/>
      
      <!-- Extract relator terms from $a -->
      <xsl:variable name="relator-terms" as="xsd:string*">
        <xsl:for-each select="tokenize($a, ',\s*')">
          <xsl:variable name="raw" select="normalize-space(.)"/>
          <xsl:variable name="outTerm" select="replace(replace($raw, '^[\.,;:\s]+', ''), '[\.,;:\s]+$', '')"/>
          <!-- comparison term lower-cased for case-insensitive match against external lookup -->
          <xsl:variable name="cmpTerm" select="lower-case($outTerm)"/>
          <xsl:if test="$external-data//item[lower-case(normalize-space(.)) = $cmpTerm]">
            <xsl:sequence select="$outTerm"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:variable>
      
      <!-- Remove relator terms from $a -->
      <xsl:variable name="name-only">
        <xsl:variable name="tokens" select="tokenize($a, ',\s*')"/>
        <xsl:variable name="filtered-tokens" as="xsd:string*">
          <xsl:for-each select="$tokens">
            <xsl:variable name="raw" select="normalize-space(.)"/>
            <xsl:variable name="outTerm" select="replace(replace($raw, '^[\.,;:\s]+', ''), '[\.,;:\s]+$', '')"/>
            <xsl:variable name="cmpTerm" select="lower-case($outTerm)"/>
            <xsl:if test="not($external-data//item[lower-case(normalize-space(.)) = $cmpTerm])">
              <xsl:sequence select="$outTerm"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="string-join($filtered-tokens, ', ')"/>
      </xsl:variable>
      
      <!-- New $a: name only -->
      <subfield code="a">
        <xsl:value-of select="$name-only"/>
      </subfield>
      
      <!-- Copy $d subfields first (if any) -->
      <xsl:apply-templates select="subfield[@code='d']"/>
      
      <!-- Create $e subfields for each relator term with comma formatting -->
      <xsl:for-each select="$relator-terms">
        <xsl:variable name="position" select="position()"/>
        <xsl:variable name="total" select="count($relator-terms)"/>
        <subfield code="e">
          <xsl:value-of select="."/>
          <xsl:if test="$position &lt; $total">,</xsl:if>
        </subfield>
      </xsl:for-each>
      
      <!-- Copy remaining subfields (excluding $a, $d, and existing $e) -->
      <xsl:apply-templates select="subfield[@code != 'a' and @code != 'd' and @code != 'e']"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
