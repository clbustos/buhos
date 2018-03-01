
# Create HTML for Tags.
module TagBuilder
  def self.tag_in_cd(revision,cd)
    TagBuilder::ContainerTagInCd.new(revision, cd)
  end


  def self.tag_bw_cd(revision,cd_start, cd_end)
    TagBuilder::ContainerTagBwCd.new(revision, cd_start, cd_end)
  end
end


require_relative 'tag_builder/container_tag_in_cd'
require_relative 'tag_builder/container_tag_bw_cd'
require_relative 'tag_builder/tag_mixin'
require_relative 'tag_builder/tag_in_cd'
require_relative 'tag_builder/tag_bw_cd'
