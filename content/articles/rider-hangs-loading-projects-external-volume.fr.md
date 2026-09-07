---
title: "Rider reste bloqué sur « Chargement des projets » ? Vérifiez les autorisations de confidentialité de macOS pour les volumes externes"
date: 2026-09-07
draft: false
tags: ["jetbrains-rider", "macos", "dotnet", "troubleshooting"]
summary: "Rider 2026.2 restait bloqué sur « Chargement des projets » pour chaque solution sur mon Mac. La vraie cause n'était ni un cache corrompu ni un plugin défaillant — c'était macOS qui révoquait discrètement l'accès de Rider à un volume externe après une mise à jour."
---

## Le symptôme

Chaque solution que j'ouvrais dans JetBrains Rider 2026.2 sur macOS restait bloquée sur « Chargement des projets ». Pas un seul projet capricieux — *tous* les projets, à chaque fois. Nouvelle solution, ancienne solution, peu importait. La fenêtre s'ouvrait, l'indicateur de chargement tournait indéfiniment, et rien dans l'interface ne donnait le moindre indice sur la cause.

Le protocole habituel pour ce genre de problème — invalider les caches, supprimer `~/Library/Caches/JetBrains/Rider2026.2`, redémarrer en mode sans échec pour écarter les plugins, tuer les processus `dotnet`/`MSBuild` orphelins — n'a rien résolu. Fait intéressant, VSCode n'avait aucun mal à compiler exactement les mêmes projets, ce qui s'est révélé être l'indice le plus important.

## Lecture du journal

Le journal de Rider lui-même (`Help → Show Log in Finder`, ou `~/Library/Logs/JetBrains/Rider2026.2/idea.log`) racontait la vraie histoire une fois que j'ai vraiment pris le temps de le consulter. Enfoui dans un mur de traces de pile, ceci apparaissait, répété des dizaines de fois :

```
SEVERE - Access to the path '/Users/me/.dotnet/sdk' is denied. Operation not permitted
WARN  - /Users/me/.dotnet: Operation not permitted
```

Le backend de Rider essayait — et échouait — d'énumérer mes SDK .NET installés, encore et encore, ce qui est exactement le genre de chose qui produit un blocage apparemment infini au chargement du projet plutôt qu'une erreur propre.

## En suivant le lien symbolique

`~/.dotnet` sur ma machine n'est pas un vrai dossier — je conserve mes installations de SDK .NET sur un volume APFS externe pour économiser l'espace sur le disque interne, et je le relie via un lien symbolique :

```bash
$ readlink ~/.dotnet
/Volumes/LLM/.dotnet
```

Le volume était monté correctement, formaté en APFS, et les permissions Unix classiques sur le dossier étaient parfaitement normales. Et surtout, **VSCode compilait les mêmes projets sans aucun problème**, ce qui excluait un véritable problème de permissions au niveau du système de fichiers — s'il s'agissait d'un simple problème de « mauvais propriétaire » ou de « mauvais chmod », tous les outils seraient bloqués, pas un seul.

## La véritable cause : TCC de macOS, pas les permissions Unix

Cette combinaison — monté, permissions correctes, mais une application bloquée et une autre qui fonctionne — est la signature du système de protection de la vie privée de macOS (TCC), et non un problème de système de fichiers. macOS traite l'accès aux volumes amovibles et externes comme sa propre catégorie protégée, contrôlée application par application, séparément des permissions de lecture/écriture classiques. Chaque application doit se voir accorder l'accès individuellement, et cette autorisation est liée à la signature de code de l'application.

Ce qui signifie : **mettre à jour Rider change sa signature, et macOS peut révoquer silencieusement une autorisation précédemment accordée lors de la mise à jour** — sans aucune invite ni erreur évidente pour vous indiquer que c'est ce qui s'est passé. VSCode, n'ayant pas été mis à jour, a conservé son autorisation existante. Rider, tout juste mis à jour vers la version 2026.2, l'a perdue.

## La solution

1. Ouvrez **Réglages Système → Confidentialité et sécurité → Fichiers et dossiers**, et vérifiez si Rider figure dans la liste avec un accès aux volumes amovibles. Vérifiez aussi **Accès complet au disque** dans le même panneau.
2. S'il est absent, périmé, ou si vous n'êtes pas sûr, forcez macOS à le réévaluer plutôt que de faire confiance à l'état mis en cache :

   ```bash
   tccutil reset SystemPolicyAllFiles com.jetbrains.rider
   ```

   (Vérifiez d'abord l'identifiant de bundle exact si vous n'êtes pas sûr — `mdls -name kMDItemCFBundleIdentifier /Applications/Rider.app`.)
3. Quittez complètement Rider (`Cmd+Q`, pas seulement fermer la fenêtre) puis relancez-le. Ouvrez une solution et surveillez une éventuelle invite d'autorisation — elle peut apparaître derrière la fenêtre principale plutôt que devant.
4. Si rien ne s'affiche automatiquement, essayez de désactiver puis réactiver l'Accès complet au disque de Rider dans les Réglages — cela force parfois macOS à redemander au lieu de réutiliser un résultat refusé.

Une fois l'autorisation accordée, les erreurs `/Volumes/...` disparaissent complètement du fichier `idea.log`, et le chargement des solutions redevient normal.

## À retenir

Si un IDE ou un outil sur macOS commence à échouer à lire quelque chose sur un volume externe ou réseau — surtout juste après une mise à jour, et surtout quand un *autre* outil peut lire exactement le même chemin sans problème — vérifiez Confidentialité et sécurité avant de toucher aux permissions de fichiers, aux caches ou aux plugins. Une sortie `ls -l` Unix qui a l'air parfaitement normale n'exclut pas que TCC bloque silencieusement le processus en coulisses.
