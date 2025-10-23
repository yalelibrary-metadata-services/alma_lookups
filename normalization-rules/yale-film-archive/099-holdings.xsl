<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim">
  
  <xsl:mode on-no-match="shallow-copy"/>
  
  <!-- Load external lookup file -->
  <xsl:variable name="lookup" 
    select="document('https://raw.githubusercontent.com/yalelibrary-metadata-services/alma_rules_testing/refs/heads/main/datasets/holdings_record.xml')"/>
  
  <xsl:template match="datafield[@tag='852']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <!-- Get the holdings ID from 001 field -->
      <xsl:variable name="holdings-id" select="string(ancestor::record/controlfield[@tag='001'])"/>
      
      <!-- Find matching record in lookup file by AVA $8 -->
      <xsl:variable name="matching-ava" 
        select="$lookup//*[local-name()='datafield'][@tag='AVA'][string(*[local-name()='subfield'][@code='8']) = $holdings-id][1]"/>
      
      <xsl:variable name="call-number" 
        select="string($matching-ava/preceding-sibling::*[local-name()='datafield'][@tag='099'][1]/*[local-name()='subfield'][@code='a'][1])"/>
      
      <!-- Check if $h already exists -->
      <xsl:variable name="existing-h" select="string(subfield[@code='h'])"/>
      
      <xsl:choose>
        <!-- If $h exists and matches lookup, copy everything as-is -->
        <xsl:when test="$existing-h != '' and $existing-h = $call-number">
          <xsl:apply-templates select="subfield"/>
        </xsl:when>
        
        <!-- If $h doesn't exist or doesn't match, replace it -->
        <xsl:otherwise>
          <!-- Copy all subfields except $h -->
          <xsl:apply-templates select="subfield[@code != 'h']"/>
          
          <!-- Add new $h with call number if found -->
          <xsl:if test="$call-number != ''">
            <subfield code="h">
              <xsl:value-of select="$call-number"/>
            </subfield>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
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
