-- Vue pour la Liste des Personnes par Groupe
CREATE OR REPLACE VIEW vue_personnes_groupes_xml AS
WITH hierarchy AS (
  SELECT  CONNECT_BY_ROOT f.Groupe_parent_id AS root_id,
          f.Groupe_enfant_id AS current_id,
          g.nom AS nom_groupe,
          LEVEL AS lvl
  FROM    fais_partie_de f
  JOIN    Groupes g ON f.Groupe_enfant_id = g.id
  CONNECT BY PRIOR f.Groupe_enfant_id = f.Groupe_parent_id
)
SELECT XMLElement("Groupes",
  XMLAgg(
    XMLElement("Groupe",
      XMLAttributes(h.root_id AS "ID", h.nom_groupe AS "NomGroupe"),
      XMLForest(
        (SELECT XMLAgg(
            XMLElement("Personne",
              XMLForest(p.id AS "ID",
                        p.nom AS "Nom",
                        p.prenom AS "Prenom",
                        p.email AS "Email")
            )
          )
          FROM Personnes p
          WHERE p.Groupe_membre_de_id = h.current_id
        ) AS "Personnes"
      )
    )
  )
).getClobVal() AS xml_data
FROM hierarchy h
WHERE h.lvl = 1;

/*
-- Essaie de requête recursive pour groupe dans un XML Forest

Erreur commençant à la ligne: 1 de la commande -
CREATE OR REPLACE VIEW vue_personnes_groupes_xml AS
WITH hierarchy AS (
  SELECT  g.id AS current_id,
          g.nom AS nom_groupe,
          LEVEL AS lvl,
          SYS_CONNECT_BY_PATH(g.nom, '/') AS path,
          CONNECT_BY_ISLEAF AS is_leaf,
          PRIOR g.id AS parent_id
  FROM    Groupes g
  LEFT JOIN fais_partie_de f ON g.id = f.Groupe_enfant_id
  CONNECT BY PRIOR g.id = f.Groupe_parent_id
)
SELECT XMLElement("Groupes",
  (SELECT XMLAgg(
      XMLElement("Groupe",
        XMLAttributes(h.current_id AS "ID", h.nom_groupe AS "NomGroupe"),
        XMLForest(
          (SELECT XMLAgg(
              XMLElement("Personne",
                XMLForest(p.id AS "ID",
                          p.nom AS "Nom",
                          p.prenom AS "Prenom",
                          p.email AS "Email")
              )
            )
            FROM Personnes p
            WHERE p.Groupe_membre_de_id = h.current_id
          ) AS "Personnes",
          (SELECT XMLAgg(
              XMLElement("Groupe",
                XMLAttributes(h2.current_id AS "ID", h2.nom_groupe AS "NomGroupe")
              )
            )
            FROM hierarchy h2
            WHERE h2.parent_id = h.current_id
          ) AS "Groupes"
        )
      )
    )
    FROM hierarchy h
    WHERE h.parent_id IS NULL
  )
).getClobVal() AS xml_data
Rapport d'erreur -
ORA-00923: mot-clé FROM absent à l'emplacement prévu
00923. 00000 -  "FROM keyword not found where expected"
*Cause:    
*Action:
*/