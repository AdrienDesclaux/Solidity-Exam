Dans le cadre de la finance décentralisée (DeFi), le développement d’un smart contract
pour gérer un système d’usines de tokens, de pools de liquidité et de mécanismes
d’échange est une étape clé pour permettre une expérience utilisateur fluide et un
écosystème robuste.
Le projet nécessite la création d’une plateforme où les utilisateurs peuvent :

1. Générer leurs propres tokens ERC20 grâce à une factory de tokens.
2. Créer des pools de liquidité à l’aide d’une factory de pools.
3. Effectuer des swaps avec des frais fixes de 2%, qui sont partiellement
   redistribués aux fournisseurs de liquidité.
4. Investir dans les pools pour devenir fournisseur de liquidité et ainsi profiter d’une
   partie des frais de swap.
5. Calculer et mettre à jour dynamiquement le ratio de liquidité pour refléter les
   échanges et les investissements.
   Spécifications Fonctionnelles :
6. Usine de Tokens (Token Factory) :
   o Permettre aux utilisateurs de déployer un contrat ERC20 personnalisable
   (nom, symbole, supply initiale).
   o Enregistrer automatiquement les tokens créés pour faciliter leur
   utilisation dans les pools de liquidité.
7. Usine de Pools (Pool Factory) :
   o Permettre la création de pools de liquidité entre deux tokens ERC20
   (Token A et Token B).
   o Initialiser chaque pool avec une liquidité minimale des deux tokens.
   o Assurer le suivi des pools actifs et leurs ratios de liquidité.
8. Mécanisme de Ratio :
   o Calculer le ratio de liquidité de chaque pool en fonction des réserves
   actuelles (par exemple, ratio = reserveA / reserveB).
   o Mettre à jour dynamiquement ce ratio après chaque swap ou ajout/retrait
   de liquidité.
9. Swap avec Frais (2%) :
   o Autoriser les échanges de Token A vers Token B (et inversement) avec un
   calcul précis des frais.
   o Redistribuer un pourcentage des frais aux fournisseurs de liquidité
   proportionnellement à leur part dans la pool.
10. Investissement dans la Pool :
    o Permettre aux utilisateurs d’investir dans une pool en y ajoutant des
    liquidités (Token A et Token B).
    o Émettre des "Pool Tokens" représentant la part de l’utilisateur dans la
    pool.
11. Redistribution des Frais :
    o Récolter 2% de chaque swap en tant que frais.
    o Redistribuer 1% aux fournisseurs de liquidité, et 1% dans une réserve de
    trésorerie (ou un fonds de gouvernance).
12. Retrait de Liquidité :
    o Permettre aux utilisateurs de retirer leurs parts de liquidité.
    o Récupérer leur part proportionnelle des tokens ainsi qu’un pourcentage
    des fees accumulés.
13. Création de Pools piégées avec des tokens piégés
    o S’assurer une réussite des fonctions précédentes pour ce type de token
    o Trouver un mécanisme permettant de récupérer les fonds de n’importe
    quel investisseur
    Contraintes Techniques :
    • Respecter le standard ERC20 pour les tokens.
    • Protéger les pools contre des attaques courantes (par exemple, protection contre
    les flash loans avec des ratios manipulés ou encore certaines failles permettant
    de voler les fonds d’une pool).
    • Éviter les erreurs d’arrondi dans les calculs de ratio et de frais.
    Étapes de Développement :
14. Développement des Contrats :
    o Développer le contrat ERC20 standard pour les tokens personnalisés.
    o Implémenter la Token Factory et la Pool Factory avec des mappings pour
    suivre les actifs créés.
    o Implémenter le mécanisme de swap avec les calculs de ratio et de frais.
15. Développement des Fonctions Secondaires :
    o Ajout de la fonctionnalité d’investissement et de retrait de liquidité.
    o Gestion de la distribution des frais.
    o Toutes fonctionnalités supplémentaires ou curiosités techniques seront
    récompensées.
    Objectif Final :
    Créer un smart contract DeFi complet, évolutif et sécurisé permettant une interaction
    fluide entre les utilisateurs, leurs tokens personnalisés, et des pools de liquidité
    dynamiques.
