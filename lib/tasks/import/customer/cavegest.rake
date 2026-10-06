namespace :import do
  namespace :customer do
    desc "Importe les clients CaveGest"
    task :cavegest do
      importer = Customer::Import::Cavegest.new(File.join(DATA_DIR, "export_clients_cavegest.xlsx"))
      begin
        importer.call
      rescue Importer::InvalidFile => e
        abort "Fichier invalide : #{e.message}"
      rescue StandardError => e
        puts "Import annulé suite à une erreur non gérée, aucune donnée enregistrée : #{e.message}"
        raise
      end
      puts importer.report
    end
  end
end
