-- Table pour enregistrer les clients de la société de développement web
CREATE TABLE Clients (
    ClientID INT AUTO_INCREMENT PRIMARY KEY, -- Identifiant unique du client
    CompanyName VARCHAR(50) NOT NULL, -- Nom de la société cliente (obligatoire)
    ContactName VARCHAR(50) NOT NULL, -- Nom du contact chez le client (obligatoire)
    Email VARCHAR(50) NOT NULL, -- Adresse e-mail du contact (obligatoire)
    Phone VARCHAR(20) NOT NULL, -- Numéro de téléphone du contact (obligatoire)
    Country VARCHAR(50) NOT NULL, -- Pays du client (obligatoire)
    CONSTRAINT chk_email CHECK (Email LIKE '%_@__%.__%'), -- Vérification de la structure de l'e-mail
    CONSTRAINT chk_phone CHECK (Phone LIKE '+%'), -- Vérification de la structure du numéro de téléphone
    CONSTRAINT chk_country CHECK (Country REGEXP '^[A-Z]') -- Vérification que le pays commence par une lettre majuscule
);

-- Table pour enregistrer les projets de développement web
CREATE TABLE Projects (
    ProjectID INT AUTO_INCREMENT PRIMARY KEY, -- Identifiant unique du projet
    ProjectName VARCHAR(50) NOT NULL, -- Nom du projet (obligatoire)
    StartDate DATE NOT NULL, -- Date de début du projet (obligatoire)
    EndDate DATE, -- Date de fin du projet
    Budget DECIMAL(15, 2) NOT NULL, -- Budget alloué au projet (obligatoire)
);

-- Table pour enregistrer les factures des projets
CREATE TABLE Invoices (
    InvoiceID INT AUTO_INCREMENT PRIMARY KEY, -- Identifiant unique de la facture
    ProjectID INT NOT NULL, -- Identifiant du projet associé à la facture (obligatoire)
    InvoiceDate DATE NOT NULL, -- Date de la facture (obligatoire)
    AmountDue DECIMAL(15, 2) NOT NULL, -- Montant dû sur la facture (obligatoire)
    Currency VARCHAR(10) NOT NULL, -- Devise de la facture (obligatoire)
    CONSTRAINT chk_currency CHECK (Currency = '$') -- Vérification que la devise est '$'
);

-- Table pour enregistrer les paiements des factures
CREATE TABLE Payments (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY, -- Identifiant unique du paiement
    InvoiceID INT NOT NULL, -- Identifiant de la facture associée au paiement (obligatoire)
    AmountPaid DECIMAL(15, 2) NOT NULL, -- Montant payé sur la facture (obligatoire)
    PaymentDate DATE NOT NULL, -- Date du paiement (obligatoire)
    FOREIGN KEY (InvoiceID) REFERENCES Invoices(InvoiceID), -- Clé étrangère pour lier les paiements aux factures
);

-- Insertion de valeurs dans la table Clients
INSERT INTO Clients (CompanyName, ContactName, Email, Phone, Country) VALUES ('ACME Web Solutions', 'John Smith', 'john.smith@acmewebsolutions.com', '+1234567890', 'United States');
INSERT INTO Clients (CompanyName, ContactName, Email, Phone, Country) VALUES ('Global Web Enterprises', 'Emily Johnson', 'emily.johnson@globalwebent.com', '+1987654321', 'United Kingdom');
INSERT INTO Clients (CompanyName, ContactName, Email, Phone, Country) VALUES ('WebTech Innovations', 'Michael Brown', 'michael.brown@webtechinnovations.com', '+1765432890', 'Australia');

-- Insertion de valeurs dans la table Projects
INSERT INTO Projects (ProjectName, StartDate, EndDate, Budget) VALUES ('E-commerce Platform Development', '2023-01-15', '2023-06-30', 50000.00);
INSERT INTO Projects (ProjectName, StartDate, EndDate, Budget) VALUES ('Corporate Intranet Redesign', '2023-03-20', '2023-09-30', 80000.00);
INSERT INTO Projects (ProjectName, StartDate, EndDate, Budget) VALUES ('Web Application Security Audit', '2023-05-10', '2023-11-30', 30000.00);

-- Insertion de valeurs dans la table Invoices
INSERT INTO Invoices (ProjectID, InvoiceDate, AmountDue, Currency) VALUES (1, '2023-04-01', 20000.00, '$');
INSERT INTO Invoices (ProjectID, InvoiceDate, AmountDue, Currency) VALUES (2, '2023-06-01', 30000.00, '$');
INSERT INTO Invoices (ProjectID, InvoiceDate, AmountDue, Currency) VALUES (3, '2023-08-01', 15000.00, '$');

-- Insertion de valeurs dans la table Payments
INSERT INTO Payments (InvoiceID, AmountPaid, PaymentDate) VALUES (1, 20000.00, '2023-04-10');
INSERT INTO Payments (InvoiceID, AmountPaid, PaymentDate) VALUES (2, 30000.00, '2023-06-15');
INSERT INTO Payments (InvoiceID, AmountPaid, PaymentDate) VALUES (3, 15000.00, '2023-08-05');


-- fonctions 

DELIMITER //
CREATE FUNCTION InsertPayment(
    p_InvoiceID INT, -- ID de la facture pour laquelle le paiement est effectué
    p_AmountPaid DECIMAL(15, 2), -- Montant payé pour cette transaction
    p_PaymentDate DATE -- Date à laquelle le paiement a été effectué
)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE v_PaymentID INT; -- Variable locale pour stocker l'ID du paiement
    
    -- Vérification de l'existence de la facture correspondante
    IF (SELECT COUNT(*) FROM Invoices WHERE InvoiceID = p_InvoiceID) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La facture spécifiée n''existe pas.'; -- Message d'erreur si la facture n'existe pas
    END IF;
    
    -- Vérification du montant payé positif
    IF p_AmountPaid <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Le montant payé doit être supérieur à zéro.'; -- Message d'erreur si le montant payé est inférieur ou égal à zéro
    END IF;
    
    -- Insertion du paiement
    INSERT INTO Payments (InvoiceID, AmountPaid, PaymentDate) VALUES (p_InvoiceID, p_AmountPaid, p_PaymentDate); -- Insertion du paiement dans la table Payments
    SET v_PaymentID = LAST_INSERT_ID(); -- Récupération de l'ID du paiement récemment inséré
    
    RETURN v_PaymentID; -- Retourne l'ID du paiement nouvellement inséré
END //
DELIMITER ;

-- test fonction 
-- Déclaration des variables de test
SET @InvoiceID := 1;
SET @AmountPaid := 20000.00;
SET @PaymentDate := '2023-04-10';

-- Appel de la fonction InsertPayment avec les valeurs de test
SELECT InsertPayment(@InvoiceID, @AmountPaid, @PaymentDate) AS NewPaymentID;


-- CalculateTotalInvoicesAmount

DELIMITER //

CREATE FUNCTION CalculateTotalInvoicesAmount(p_ProjectID INT) -- Fonction pour calculer le montant total des factures pour un projet donné
RETURNS DECIMAL(15, 2) -- La fonction renvoie un montant décimal avec une précision de 15 chiffres au total et 2 décimales
DETERMINISTIC -- Indique que la fonction est déterministe, c'est-à-dire que pour un ensemble de valeurs donné, elle retournera toujours le même résultat
BEGIN
    DECLARE v_TotalAmount DECIMAL(15, 2); -- Déclaration d'une variable locale pour stocker le montant total des factures
    
    -- Sélection de la somme des montants dus pour le projet spécifié
    SELECT SUM(AmountDue) INTO v_TotalAmount
    FROM Invoices
    WHERE ProjectID = p_ProjectID;
    
    -- Vérification si le montant total est nul
    IF v_TotalAmount IS NULL THEN
        SET v_TotalAmount := 0.00; -- Si le montant total est nul, on le fixe à zéro
    END IF;
    
    RETURN v_TotalAmount; -- Renvoie le montant total des factures pour le projet spécifié
END //

DELIMITER ;

-- test fonction 
-- Déclaration de la variable de test pour l'ID du projet
SET @ProjectID := 1;

-- Appel de la fonction CalculateTotalInvoicesAmount avec l'ID de projet spécifié
SELECT CalculateTotalInvoicesAmount(@ProjectID) AS TotalInvoicesAmount;


-- Création de la vue pour les clients triés par pays
CREATE VIEW ClientsView AS
SELECT ClientID, CompanyName, ContactName, Email, Phone, Country
FROM Clients
ORDER BY Country;

-- Création de la vue pour les projets triés par StartDate et Budget
CREATE VIEW ProjectsView AS
SELECT ProjectID, ProjectName, StartDate, EndDate, Budget
FROM Projects
ORDER BY StartDate, Budget;



-- procedure 
DELIMITER //

-- Procédure pour insérer un paiement dans la table "Payments" en hashant l'ID de la facture
CREATE PROCEDURE InsertPayment(
    p_InvoiceID INT, -- ID de la facture pour laquelle le paiement est effectué
    p_AmountPaid DECIMAL(15, 2), -- Montant payé pour cette transaction
    p_PaymentDate DATE -- Date à laquelle le paiement a été effectué
)
BEGIN
    DECLARE v_PaymentID INT; -- Variable locale pour stocker l'ID du paiement

    -- Vérification de l'existence de la facture correspondante
    SELECT COUNT(*) INTO @invoiceCount FROM Invoices WHERE InvoiceID = p_InvoiceID;
    IF @invoiceCount = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La facture spécifiée n''existe pas.'; -- Message d'erreur si la facture n'existe pas
    END IF;

    -- Hashage de l'ID de la facture
    DECLARE hashedID VARCHAR(255);
    SET hashedID = SHA2(CONCAT('Invoice_', CAST(p_InvoiceID AS CHAR)), 256);

    -- Insertion du paiement avec l'ID hashé
    INSERT INTO Payments (InvoiceID, AmountPaid, PaymentDate, HashedInvoiceID) VALUES (p_InvoiceID, p_AmountPaid, p_PaymentDate, hashedID);
    SET v_PaymentID = LAST_INSERT_ID(); -- Récupération de l'ID du paiement récemment inséré
END //

DELIMITER //

-- Procédure pour mettre à jour le montant payé dans la table "Payments" pour un ID de paiement donné
CREATE PROCEDURE UpdatePayment(
    p_PaymentID INT, -- ID du paiement à mettre à jour
    p_NewAmountPaid DECIMAL(15, 2) -- Nouveau montant payé pour cette transaction
)
BEGIN
    UPDATE Payments
    SET AmountPaid = p_NewAmountPaid
    WHERE PaymentID = p_PaymentID;
END //

DELIMITER //

-- Procédure pour supprimer un paiement de la table "Payments" pour un ID de paiement donné
CREATE PROCEDURE DeletePayment(
    p_PaymentID INT -- ID du paiement à supprimer
)
BEGIN
    DELETE FROM Payments
    WHERE PaymentID = p_PaymentID;
END //

DELIMITER //

-- Procédure pour récupérer les informations d'un paiement de la table "Payments" pour un ID de paiement donné
CREATE PROCEDURE GetPayment(
    p_PaymentID INT -- ID du paiement dont on veut les informations
)
BEGIN
    SELECT PaymentID, InvoiceID, AmountPaid, PaymentDate FROM Payments
    WHERE PaymentID = p_PaymentID;
END //

DELIMITER //

-- test 

CALL InsertPayment(1, 100.00, '2023-11-09');

CALL UpdatePayment(1, 150.00);

CALL DeletePayment(1);

CALL GetPayment(1);


-- procedure client 

DELIMITER //

-- Procédure pour insérer un nouveau client dans la table "Clients"
CREATE PROCEDURE InsertClient(
    p_CompanyName VARCHAR(50), -- Nom de la société cliente
    p_ContactName VARCHAR(50), -- Nom du contact chez le client
    p_Email VARCHAR(50), -- Adresse e-mail du contact
    p_Phone VARCHAR(20), -- Numéro de téléphone du contact
    p_Country VARCHAR(50) -- Pays du client
)
BEGIN
    -- Insertion du nouveau client
    INSERT INTO Clients (CompanyName, ContactName, Email, Phone, Country) 
    VALUES (p_CompanyName, p_ContactName, p_Email, p_Phone, p_Country);
END //

DELIMITER //

-- Procédure pour mettre à jour les informations d'un client dans la table "Clients"
CREATE PROCEDURE UpdateClient(
    p_ClientID INT, -- ID du client à mettre à jour
    p_CompanyName VARCHAR(50), -- Nouveau nom de la société cliente
    p_ContactName VARCHAR(50), -- Nouveau nom du contact chez le client
    p_Email VARCHAR(50), -- Nouvelle adresse e-mail du contact
    p_Phone VARCHAR(20), -- Nouveau numéro de téléphone du contact
    p_Country VARCHAR(50) -- Nouveau pays du client
)
BEGIN
    -- Mise à jour des informations du client
    UPDATE Clients
    SET CompanyName = p_CompanyName,
        ContactName = p_ContactName,
        Email = p_Email,
        Phone = p_Phone,
        Country = p_Country
    WHERE ClientID = p_ClientID;
END //

DELIMITER //

-- Procédure pour supprimer un client de la table "Clients"
CREATE PROCEDURE DeleteClient(
    p_ClientID INT -- ID du client à supprimer
)
BEGIN
    -- Suppression du client
    DELETE FROM Clients
    WHERE ClientID = p_ClientID;
END //

DELIMITER //

-- Procédure plus complexe pour vérifier si l'utilisateur est un professionnel
CREATE PROCEDURE CheckProfessionalism(
    p_ClientID INT -- ID du client à vérifier
)
BEGIN
    DECLARE clientCountry VARCHAR(50);
    DECLARE message VARCHAR(255);
    
    -- Récupération du pays du client
    SELECT Country INTO clientCountry
    FROM Clients
    WHERE ClientID = p_ClientID;
    
    -- Vérification si le pays commence par une lettre majuscule
    IF BINARY LEFT(clientCountry, 1) = UPPER(LEFT(clientCountry, 1)) THEN
        SET message = 'Le client  avec MAJ.';
    ELSE
        SET message = 'Le client n''est pas  avec MAJ.';
    END IF;
    
    -- Affichage du message
    SELECT message;
END //

DELIMITER //
