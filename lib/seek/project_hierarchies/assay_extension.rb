module Seek
  module ProjectHierarchies
    module AssayExtension
      Assay.class_eval do
        def projects_and_descendants
          projects.collect { |proj| [proj] + proj.descendants }.flatten.uniq
        end
      end
    end
  end
end