require 'open3'

class XcodeBuildTagger
  def self.get_marketing_version
    marketing_version, err, st = Open3.capture3('agvtool mvers -terse1')
    throw err if not st.success?
    marketing_version.slice! "\n"
    marketing_version
  end

  def self.get_next_build_version(label, marketing_version)
    # Get all git tags as a string for this label & marketing version
    tag_prefix = get_tag_prefix label, marketing_version
    filtered_tags, err, st = Open3.capture3('git', 'tag', '-l', tag_prefix + '*')
    throw err if not st.success?

    # Convert into an array
    filtered_tags = filtered_tags.split("\n")

    # Strip stags of the prefix, and convert to integers
    build_versions = filtered_tags.map { |tag| tag[tag_prefix.length, tag.length - tag_prefix.length].to_i }

    # Sort & get the last used build version number
    build_versions.sort!
    last_build_version = build_versions.last

    if last_build_version
      new_build_version = last_build_version + 1
    else
      new_build_version = 1
    end

    new_build_version.to_s
  end

  def self.get_tag_prefix(label, marketing_version)
    label + '-' + marketing_version + '-'
  end

  def self.set_build_version(build_version)
    out, err, st = Open3.capture3('agvtool', 'new-version', '-all', build_version)
    throw err if not st.success?
  end

  def self.bump_version_and_set_tag(label)
    marketing_version = get_marketing_version
    next_build_version = get_next_build_version label, marketing_version
    set_build_version next_build_version

    next_tag = get_tag_prefix(label, marketing_version) + next_build_version
    result, err, st = Open3.capture3('git', 'tag', next_tag)
    throw err if not st.success?    
  end
end
