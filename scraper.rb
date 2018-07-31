#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require_relative 'lib/remove_notes'
require_relative 'lib/unspan_all_tables'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator RemoveNotes
  decorator WikidataIdsDecorator::Links
  decorator UnspanAllTables

  field :members do
    members_table.flat_map do |table|
      table.xpath('.//tr[td]').map { |tr| data = fragment(tr => MemberRow).to_h }
    end
  end

  private

  def members_table
    noko.xpath('//table[.//th[contains(.,"Diputado")]]').drop(1)
  end
end

class MemberRow < Scraped::HTML
  field :name do
    tds[1].css('a').map(&:text).map(&:tidy).first rescue binding.pry
  end

  field :id do
    tds[1].css('a/@wikidata').map(&:text).first
  end

  field :faction do
    tds[2].css('a').map(&:text).map(&:tidy).first rescue binding.pry
  end 

  field :faction_id do
    tds[2].css('a/@wikidata').map(&:text).first
  end

  field :area do
    tds[0].text.tidy
  end

  private

  def tds
    noko.css('td')
  end
end

url = 'https://es.wikipedia.org/wiki/LV_periodo_legislativo_del_Congreso_Nacional_de_Chile'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name area faction])
