# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Third-party dependencies
pin "apexcharts", to: "https://cdn.jsdelivr.net/npm/apexcharts@3.45.1/dist/apexcharts.esm.js"

# Pin FlatPack controllers from the engine
pin_all_from FlatPack::Engine.root.join("app/javascript/flat_pack/controllers"), under: "controllers/flat_pack", to: "flat_pack/controllers", preload: false
pin_all_from FlatPack::Engine.root.join("app/javascript/flat_pack/tiptap"), under: "flat_pack/tiptap", to: "flat_pack/tiptap", preload: false
pin "flat_pack/heroicons", to: "flat_pack/heroicons.js", preload: false
