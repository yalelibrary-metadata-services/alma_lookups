<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim">
  
  <xsl:mode on-no-match="shallow-copy"/>
  
  <!-- Load external lookup file -->
  <xsl:variable name="lookup" as="document-node()?" 
    select="document('https://raw.githubusercontent.com/yalelibrary-metadata-services/alma_rules_testing/refs/heads/main/datasets/nine_records.xml')"/>
  
  <xsl:template match="datafield[@tag='852']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <!-- Get the temp ID from 852 $h -->
      <xsl:variable name="temp-id" select="normalize-space(subfield[@code='h'])"/>
      
      <!-- Find matching record in lookup file by AVA $d -->
      <xsl:variable name="call-number" 
        select="normalize-space($lookup//*[local-name()='datafield'][@tag='AVA'][*[local-name()='subfield'][@code='d'][normalize-space(.) = $temp-id]]/preceding-sibling::*[local-name()='datafield'][@tag='099']/*[local-name()='subfield'][@code='a'][1])"/>
      
      <!-- Process subfields -->
      <xsl:for-each select="subfield">
        <xsl:choose>
          <xsl:when test="@code='h' and $call-number != ''">
            <subfield code="h">
              <xsl:value-of select="$call-number"/>
            </subfield>
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy>
              <xsl:apply-templates select="@*|node()"/>
            </xsl:copy>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>
  
  <!-- Add 866 if it doesn't exist -->
  <xsl:template match="record[not(datafield[@tag='866'])]">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <datafield tag="866" ind1="4" ind2="1">
        <subfield code="8">0</subfield>
        <subfield code="a">reel 1</subfield>
      </datafield>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
