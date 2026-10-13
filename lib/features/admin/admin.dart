/// Administration features — Hub et formulaires
library;

export 'admin_hub_page.dart';
// admin_forms.dart : composants de formulaire partagés (adminTextField,
// AdminFormPreviewLayout, AdminImageUploadField, LocalizedFieldGroup).
// Les formulaires eux-mêmes (Atelier, Média, Galerie, Événement) vivent
// chacun dans leur propre fichier — importés directement là où ils sont
// utilisés (voir admin_content_manager.dart), pas réexportés ici.
export 'admin_forms.dart';
// Connexion par pseudo + gestion du compte admin (nouveau)
export 'admin_credentials_service.dart';
export 'admin_account_page.dart';