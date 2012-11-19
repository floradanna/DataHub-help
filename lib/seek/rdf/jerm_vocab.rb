module Seek
  module Rdf
    class JERMVocab < RDF::Vocabulary("http://www.mygrid.org.uk/ontology/JERMOntology#")
      @types = {DataFile=>"Data",Model=>"Model",Sop=>"SOP",Assay=>"Assay"}
      property :Data


      #returns the correct Class IRI accrording to the class, or instance, passed in - or nil if its not recognised
      def self.for_type type
        type = type.class unless type.is_a?(Class)
        t=@types[type]
        t=self.send(t) unless t.nil?
        t
      end

    end
  end
end