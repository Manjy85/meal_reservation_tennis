# Sécurité et données personnelles

Ce que fait le code, et ce qu'il reste à configurer à la main dans la console
Firebase.

## Ce qui est en place

Le projet reste sur le forfait gratuit **Spark** : pas de Cloud Functions,
les règles Firestore sont la seule protection côté serveur.

- **Mots de passe** : gérés uniquement par Firebase Authentication (hachés
  avec scrypt), jamais écrits dans Firestore. Les écrans ne font plus de
  `trim()` sur le mot de passe.
- **Règles Firestore** (`firestore.rules`) :
  - profils, produits et dates validés (champs autorisés, types, tailles,
    email = celui du compte connecté) ;
  - une commande n'est acceptée que pour soi, au statut « En attente », sur
    une date/un service ouverts par le restaurateur et non passés, avec des
    champs contrôlés ;
  - le compteur de numéros ne peut qu'avancer de 1, et seulement en même
    temps que la création de la commande qui porte ce numéro (impossible de
    le remettre à zéro ou de bloquer les commandes du jour) ;
  - statut de commande limité aux 4 valeurs, modifiable par les admins seulement.
- **Limite connue** : les règles ne savent pas parcourir la liste des
  articles, donc un client malveillant pourrait envoyer de faux prix. L'app
  admin compare chaque commande à la carte et affiche **« Prix à vérifier »**
  en cas d'écart. Le paiement se faisant sur place, il suffit d'encaisser le
  prix de la carte. (Avec le forfait Blaze, une Cloud Function pourrait
  calculer les prix côté serveur.)
- **Suppression de compte** (menu compte de l'app client → *Supprimer mon
  compte*) : mot de passe redemandé, commandes passées anonymisées (gardées
  pour le restaurateur sans nom/email/téléphone), puis profil et compte
  supprimés.
- **Mot de passe oublié** sur l'écran de connexion client, et e-mail de
  vérification envoyé à l'inscription.
- **App Check** activé dans les deux apps (`lib/app_check.dart`, gratuit sur
  Spark) : Play Integrity sur Android, App Attest sur iOS, fournisseur
  *debug* en mode debug.

## Déploiement des règles

Pas besoin de la CLI : console Firebase → *Firestore Database* → onglet
*Règles* → coller le contenu de `firestore.rules` → *Publier*. L'onglet
propose aussi un *Rules Playground* pour tester une requête avant de publier.

Les anciennes versions de l'app restent compatibles avec ces règles, mais la
suppression de compte ne marche qu'une fois les règles publiées.

Dans Firestore, supprimer aussi à la main tout champ `password` qui
traînerait dans d'anciens documents `users`.

## À régler dans la console Firebase

**Authentication → Settings**
- *User actions* : activer **Email enumeration protection**.
- *Password policy* : longueur minimale 8 ou plus (l'app affiche l'erreur
  Firebase si le mot de passe est refusé).
- Compte restaurateur : mot de passe long et unique. Pour de la MFA, il faut
  passer à *Identity Platform* (Authentication → Settings → Upgrade).

**Authentication → Templates** : mettre en français les e-mails de
vérification et de réinitialisation.

**App Check**
1. *Apps* → pour chaque app Android (client et admin) : enregistrer **Play
   Integrity** avec l'empreinte **SHA-256** de la clé de signature
   (`cd android && ./gradlew signingReport`, puis celle de Google Play App
   Signing une fois sur le Play Store).
2. En debug, l'app écrit dans les logs un *debug token* (`adb logcat | grep -i
   "debug token"`) : l'ajouter dans *Manage debug tokens*.
3. Web (test dans Chrome) : créer une clé reCAPTCHA v3, l'enregistrer dans
   App Check, et lancer avec
   `flutter run -d chrome --dart-define=RECAPTCHA_SITE_KEY=<clé>`.
   Sans clé, App Check n'est simplement pas activé sur le web.
4. Observer l'onglet *Metrics* quelques jours : quand ~100 % des requêtes
   sont vérifiées, cliquer **Enforce** pour Cloud Firestore et Authentication.
   Avant ça, rien n'est bloqué.

## Avant une publication sur les stores

- [ ] Identifiant d'app réel à la place de `com.example.*` (et réenregistrer
      les apps Android dans Firebase).
- [ ] Keystore de release (hors git, sauvegardé) au lieu de la clé debug.
- [ ] Publier en `.aab` : `flutter build appbundle --flavor client -t lib/main.dart`.
- [ ] Politique de confidentialité en ligne (données : nom, prénom, e-mail,
      téléphone, commandes ; finalité : gestion des réservations ; hébergement
      Google Cloud Francfort ; durée de conservation ; contact).
- [ ] Page web expliquant comment supprimer son compte (exigée par Google Play
      en plus du bouton dans l'app).
- [ ] Formulaire *Sécurité des données* (Play) / *App Privacy* (Apple).
- [ ] iOS : créer le dossier `ios/` (`flutter create --platforms=ios .`) sur
      un Mac, enregistrer les apps iOS dans Firebase, activer App Attest.
- [ ] Définir une durée de conservation des commandes (ex. anonymiser au-delà
      d'un an).
