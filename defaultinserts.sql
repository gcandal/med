INSERT INTO Organization VALUES (DEFAULT, 'Org');
INSERT INTO Account VALUES (DEFAULT, 'José', 'a@a.pt',
                            '445fff776df2293d242b261ba0f0d35be6c5b5a5110394fe8942a21e4d7af759fa277f608c3553ee7b3f8f64fce174b31146746ca8ef67dd37eedf70fe79ef9d',
                            'bea95c126335da5b92c91de01635311ede91a58f0ca0d9cb0344462333c35c9ef12977e976e2e8332861cff2c4efa42c653214b626ed96a76ba19ed0e414b71a',
                            '123456789',
                            DEFAULT,
                            CURRENT_DATE + INTERVAL '1 year',
                            -1);

INSERT INTO Account VALUES (DEFAULT, 'b', 'b@b.pt',
                            '6b9f904771f21b6d9d017582d9a001c41eef2dd5128ff80fd1985d8f1f2e62fe5e23b4e77c16adea3e86eaf8353acc55e93f982419c9f87356e3a805ef7fae16',
                            'beb281b875e9c11fb6f8290fb7952e6da45dcd50f903299b374c6d8c816eca7dfa66c9d2b70bd3900a0b9c666eaf656505739c370ca2f2a788c33e1ff16a4736',
                            '987654321',
                            DEFAULT,
                            CURRENT_DATE + INTERVAL '1 year',
                            -1);

INSERT INTO Account VALUES (DEFAULT, 'c', 'c@c.pt',
                            'b13188a1fb01f1b9c41e9229dacf2c030d6ea18bd14c0d462dc488e5bbe7fb28d7a33ac16a8bc5989ea7e1af2d4a0476cfeea2b3e4c82253cd70e42688e60988',
                            '6deba07b456d9594d85baa07c911bd7ae9ca659ed2b16760d78b6c443252ac0d2357b8363780b1dc47eccc49b12989a61da2727d4519b241a5eb5768046a72e1',
                            '012345678',
                            DEFAULT);

INSERT INTO PrivatePayer VALUES (DEFAULT, 1, 'Aquele Mano', 5);
INSERT INTO OrgAuthorization VALUES (1, 1, 'AdminVisible');
INSERT INTO OrgInvitation VALUES (1, 1, '111111111', FALSE);
INSERT INTO OrgInvitation VALUES (1, 1, '012345678', FALSE, FALSE, '2014-06-02 20:36:43.206615');
INSERT INTO Professional
VALUES (DEFAULT, 2, 1, 'asdrubal', NULL, '123456789', '987654321', '2014-06-02 20:36:43.206615');
INSERT INTO Professional
VALUES (DEFAULT, 2, 1, 'asdrubal incompleto', NULL, NULL, '987654321', '2014-06-02 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 1, 1, 'Quim Manel', NULL, NULL, '111111111', '2014-06-02 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 1, 1, 'Quim Ze', NULL, NULL, NULL, '2014-06-22 20:36:43.206615');
INSERT INTO Professional VALUES (DEFAULT, 1, 1, 'Quim Ze Completo', NULL, NULL, NULL, '2014-06-12 20:36:43.206615');
INSERT INTO Professional
VALUES (DEFAULT, 1, 1, 'Quim Ze Completo', NULL, NULL, '159268753', '2014-07-02 20:36:43.206615');
INSERT INTO OrgAuthorization VALUES (1, 2, 'Visible');