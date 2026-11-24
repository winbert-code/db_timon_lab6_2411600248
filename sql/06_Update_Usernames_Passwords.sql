-- =============================================================
-- Rename the added accounts to first-name usernames and reset
-- their passwords to <firstname>123.
--
-- Run once after 05_Additional_Teachers_Students.sql.
-- Re-running is harmless: the old usernames will no longer match.
-- =============================================================

USE DB_Timon;

UPDATE users SET username = 'reyjay',
  password_hash = 'pbkdf2_sha256$100000$VAKhkQp2E9DFD4sX135Akg==$M4smU7324sjDrYONl8bT238Zh3b+iOLiRhQ7nD00r2s='
WHERE username = 'reyjay.cagang';

UPDATE users SET username = 'joseph',
  password_hash = 'pbkdf2_sha256$100000$/xteG/wNBg3I30iTjd58Ew==$FIliiE4hV/NNrXReylEErmEMc7i/lZW24RLs1xXeJOM='
WHERE username = 'joseph.sabello';

UPDATE users SET username = 'ben',
  password_hash = 'pbkdf2_sha256$100000$dGV+o6QvSGoXD+LpJ2Fz6Q==$vePE0Y6h+Fs5O2T8U9tl9Ot2teYm3RqSdsdLaSKau+o='
WHERE username = 'ben.ten';

UPDATE users SET username = 'steven',
  password_hash = 'pbkdf2_sha256$100000$gG2W+/10GBH/NRSfufan4Q==$T0P1CB0ElGjLOUZ3OhKX4MtQiv6sqbRus7NLtDyKTnY='
WHERE username = 'steven.harley';

UPDATE users SET username = 'optimus',
  password_hash = 'pbkdf2_sha256$100000$N++aSN9Alaf6VaFyvt9UqA==$C/pTYl5SSex3+csMakLFBt4MC/GwZs3Mn/TGDxnsxOs='
WHERE username = 'optimus.prime';

UPDATE users SET username = 'evo',
  password_hash = 'pbkdf2_sha256$100000$UJKzn7QNAOoEpf1s9aRvVw==$zDGBKYoZ8KaO4dJRtClxN4pRLqhlOTjuIqa9V/ls1nM='
WHERE username = 'evo.lin';

UPDATE users SET username = 'joe',
  password_hash = 'pbkdf2_sha256$100000$oNr2E+xIRHufWl51moB5Sw==$F/mig8ZkLP0AZBiGGsPqq+RGfpAnGbI/+/0Kb2zJVgA='
WHERE username = 'joe.tan';

-- Verification
SELECT u.user_id, u.username, r.role_name
FROM users u JOIN roles r ON r.role_id = u.role_id
ORDER BY u.user_id;
