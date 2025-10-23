<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:marc="http://www.loc.gov/MARC21/slim">
  <xsl:mode on-no-match="shallow-copy"/>
  
  <!-- Base URL for external MARC data -->
  <xsl:variable name="base-url">https://raw.githubusercontent.com/yalelibrary-metadata-services/alma_rules_testing/refs/heads/main/datasets/aap_index</xsl:variable>
  
  <xsl:template match="datafield[@tag='100' or @tag='600' or @tag='700']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      
      <!-- Get current field for comparison -->
      <xsl:variable name="current-field" select="."/>
      <xsl:variable name="field-tag" select="string(@tag)"/>
      <xsl:variable name="ind1" select="string(@ind1)"/>
      <xsl:variable name="has-d" select="exists(subfield[@code='d'])"/>
      
      <!-- Determine the URL based on field, indicator 1, and subfield $d -->
      <xsl:variable name="external-url">
        <xsl:choose>
          <!-- Field 600 -->
          <xsl:when test="$field-tag = '600'">
            <xsl:value-of select="concat($base-url, '/600/600.xml')"/>
          </xsl:when>
          
          <!-- Field 100 -->
          <xsl:when test="$field-tag = '100' and $ind1 = '0'">
            <xsl:value-of select="concat($base-url, '/100/0/0.xml')"/>
          </xsl:when>
          <xsl:when test="$field-tag = '100' and $ind1 = '1' and $has-d">
            <xsl:value-of select="concat($base-url, '/100/1/d.xml')"/>
          </xsl:when>
          <xsl:when test="$field-tag = '100' and $ind1 = '1' and not($has-d)">
            <xsl:value-of select="concat($base-url, '/100/1/no_d.xml')"/>
          </xsl:when>
          <xsl:when test="$field-tag = '100' and $ind1 = '3'">
            <xsl:value-of select="concat($base-url, '/100/3/3.xml')"/>
          </xsl:when>
          
          <!-- Field 700 -->
          <xsl:when test="$field-tag = '700' and $ind1 = '1' and $has-d">
            <xsl:value-of select="concat($base-url, '/700/1/d.xml')"/>
          </xsl:when>
          <xsl:when test="$field-tag = '700' and $ind1 = '1' and not($has-d)">
            <xsl:value-of select="concat($base-url, '/700/1/no_d.xml')"/>
          </xsl:when>
          <xsl:when test="$field-tag = '700' and ($ind1 = '0' or $ind1 = '3')">
            <xsl:value-of select="concat($base-url, '/700/2_3/2_3.xml')"/>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      
      <!-- Load external MARC data if URL is available -->
      <xsl:variable name="external-marc-data" as="document-node()?" select="if(string-length($external-url) > 0) then document($external-url) else ()"/>
      
      <!-- Check for exact match in external MARC data -->
      <xsl:variable name="has-exact-match" as="xsd:boolean">
        <xsl:choose>
          <xsl:when test="exists($external-marc-data)">
            <xsl:variable name="match-found" as="xsd:boolean*">
              <xsl:for-each select="$external-marc-data//datafield[@tag=$field-tag] | $external-marc-data//marc:datafield[@tag=$field-tag]">
                <xsl:variable name="external-field" select="."/>
                
                <!-- Compare indicators -->
                <xsl:variable name="indicators-match" select="
                  $current-field/@ind1 = $external-field/@ind1 and 
                  $current-field/@ind2 = $external-field/@ind2"/>
                
                <!-- Get the correct subfield count for comparison -->
                <xsl:variable name="external-subfield-count" select="count($external-field/subfield) + count($external-field/marc:subfield)"/>
                
                <!-- Compare subfields (count, codes, and content) -->
                <xsl:variable name="subfields-match" as="xsd:boolean">
                  <xsl:choose>
                    <xsl:when test="count($current-field/subfield) != $external-subfield-count">
                      <xsl:sequence select="false()"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:variable name="subfield-comparisons" as="xsd:boolean*">
                        <xsl:for-each select="$current-field/subfield">
                          <xsl:variable name="pos" select="position()"/>
                          <xsl:variable name="current-subfield" select="."/>
                          <xsl:variable name="external-subfield" select="($external-field/subfield[$pos], $external-field/marc:subfield[$pos])[1]"/>
                          
                          <xsl:sequence select="
                            $current-subfield/@code = $external-subfield/@code and
                            string($current-subfield) = string($external-subfield)"/>
                        </xsl:for-each>
                      </xsl:variable>
                      <xsl:sequence select="every $comp in $subfield-comparisons satisfies $comp = true()"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                
                <!-- Return true if both indicators and subfields match -->
                <xsl:sequence select="$indicators-match and $subfields-match"/>
              </xsl:for-each>
            </xsl:variable>
            
            <!-- Return true if any match was found -->
            <xsl:sequence select="some $match in $match-found satisfies $match = true()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="false()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      
      <!-- Copy all existing subfields -->
      <xsl:apply-templates select="subfield"/>
      
      <!-- Add $9 TRUE if exact match found -->
      <xsl:if test="$has-exact-match">
        <subfield code="9">
          <xsl:text>TRUE</xsl:text>
        </subfield>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
