--
-- База данных: shop
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`%` PROCEDURE `purchase_add` (IN `p_user_id` INT UNSIGNED, IN `p_product_id` INT UNSIGNED, IN `type_cart` BOOLEAN)   BEGIN
    DECLARE p_purchase_id INT UNSIGNED;
    DECLARE purchase_type ENUM('cart', 'favorite');
    
    SET purchase_type = 'favorite';
    IF type_cart = 1 THEN
    	SET purchase_type = 'cart';
    END IF;
    
    SELECT id INTO p_purchase_id
    FROM purchase
    WHERE user_id = p_user_id
    AND status = purchase_type
    LIMIT 1;

    IF p_purchase_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =  'Не удается найти избранное/корзину';
    END IF;
	
    IF EXISTS(
        SELECT 1
        FROM purchase_product
        WHERE purchase_id = p_purchase_id
        AND product_id = p_product_id
    ) THEN
    	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =  'Товар уже в избранном/корзине';
    END IF;
    
    INSERT INTO purchase_product (purchase_id, product_id)
    VALUES (p_purchase_id, p_product_id);
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `purchase_cart` (IN `p_user_id` INT UNSIGNED)   BEGIN
	DECLARE p_purchase_id INT UNSIGNED;
    
    SELECT id INTO p_purchase_id
    FROM purchase
    WHERE user_id = p_user_id AND status = 'cart'
    LIMIT 1;
    
    IF p_purchase_id IS NULL THEN
    	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Не удается найти корзину';
    END IF;
    
    IF NOT EXISTS (
    	SELECT 1
        FROM purchase_product
        WHERE purchase_id = p_purchase_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'У пользователя пустая корзина';
    END IF;

    UPDATE purchase
    SET status = 'expect'
    WHERE id = p_purchase_id;
    
	UPDATE purchase_product pp
    JOIN product p ON pp.product_id = p.id
    SET pp.price = p.current_price
    WHERE pp.purchase_id = p_purchase_id;
    
    INSERT INTO purchase (user_id, status)
    values (p_user_id, 'cart');
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `purchase_delete` (IN `p_user_id` INT UNSIGNED, IN `p_product_id` INT UNSIGNED, IN `type_cart` BOOLEAN)   BEGIN
    DECLARE p_purchase_id INT UNSIGNED;
	DECLARE purchase_type ENUM('cart', 'favorite');
    
    SET purchase_type = 'favorite';
    IF type_cart = 1 THEN
    	SET purchase_type = 'cart';
    END IF;
    
    SELECT id INTO p_purchase_id
    FROM purchase
    WHERE user_id = p_user_id
    AND status = purchase_type
    LIMIT 1;
    
	IF p_purchase_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Не удается найти избранное/корзину';
    END IF;
    
 	IF NOT EXISTS(
        SELECT 1
        FROM purchase_product
        WHERE purchase_id = p_purchase_id
        AND product_id = p_product_id
    ) THEN
    	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =  'Товара нет в избранном/корзине';
    END IF;
    
    DELETE FROM purchase_product
    WHERE purchase_id = p_purchase_id
    AND product_id = p_product_id;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `purchase_expect` (IN `p_purchase_id` INT UNSIGNED, IN `is_pass` BOOLEAN)   BEGIN
    IF EXISTS (
        SELECT 1
        FROM purchase
        WHERE id = p_purchase_id AND status = 'expect'
    ) THEN
        IF is_pass THEN
            UPDATE purchase
            SET status = 'pass'
            WHERE id = p_purchase_id;
        ELSE
            UPDATE purchase
            SET status = 'cancel'
            WHERE id = p_purchase_id;
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Статус покупки не ожидаемый';
    END IF;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `user_games` (IN `p_user_id` INT UNSIGNED)   BEGIN
    SELECT p.slug, p.name, p.logline
    FROM product p
    JOIN purchase_product pp ON p.id = pp.product_id
    JOIN purchase pur ON pp.purchase_id = pur.id
    WHERE pur.user_id = p_user_id AND pur.status = 'pass'
    ORDER BY pur.date_update DESC;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `user_orders` (IN `p_user_id` INT UNSIGNED)   BEGIN
    SELECT pur.id, pur.sum, p.slug, p.name, pp.price
    FROM product p
    JOIN purchase_product pp ON p.id = pp.product_id
    JOIN purchase pur ON pp.purchase_id = pur.id
    WHERE pur.user_id = p_user_id AND pur.status = 'pass'
    ORDER BY pur.date_update DESC;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы product
--

CREATE TABLE product (
  id int(10) UNSIGNED NOT NULL,
  slug varchar(100) NOT NULL,
  name varchar(100) NOT NULL DEFAULT 'Товар',
  logline varchar(255) NOT NULL DEFAULT 'Краткое описание товара',
  current_price int(11) NOT NULL DEFAULT 3999,
  old_price int(11) DEFAULT NULL,
  release_date timestamp NOT NULL DEFAULT current_timestamp(),
  product_id int(10) UNSIGNED DEFAULT NULL,
  description text NOT NULL DEFAULT 'Описание товара',
  localization enum('full','text') DEFAULT 'full',
  requirement text NOT NULL DEFAULT 'Системные требования продукта',
  status enum('available','not_available') NOT NULL DEFAULT 'available'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Структура таблицы product_file
--

CREATE TABLE product_file (
  id int(10) UNSIGNED NOT NULL,
  product_id int(10) UNSIGNED NOT NULL,
  slug varchar(255) NOT NULL,
  type enum('video','image','file') NOT NULL,
  subtype enum('background','card','product','update') NOT NULL,
  version varchar(50) DEFAULT NULL,
  description text DEFAULT NULL,
  date_add timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Дублирующая структура для представления product_info
-- (См. Ниже фактическое представление)
--
CREATE TABLE `product_info` (
`id` int(10) unsigned
,`slug` varchar(100)
,`name` varchar(100)
,`logline` varchar(255)
,`current_price` int(11)
,`old_price` int(11)
,`release_date` timestamp
,`is_new` int(1)
,`product_id` int(10) unsigned
,`description` text
,`localization` enum('full','text')
,`requirement` text
,`status` enum('available','not_available')
,`image_card` varchar(123)
,`image_background` varchar(129)
,`video_background` varchar(129)
,`discount` decimal(15,0)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления product_relevance
-- (См. Ниже фактическое представление)
--
CREATE TABLE `product_relevance` (
`id` int(10) unsigned
,`relevance` decimal(28,5)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления product_sales
-- (См. Ниже фактическое представление)
--
CREATE TABLE `product_sales` (
`id` int(10) unsigned
,`sales` bigint(21)
);

-- --------------------------------------------------------

--
-- Структура таблицы product_tag
--

CREATE TABLE product_tag (
  id int(10) UNSIGNED NOT NULL,
  product_id int(10) UNSIGNED NOT NULL,
  tag_id int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Структура таблицы purchase
--

CREATE TABLE purchase (
  id int(10) UNSIGNED NOT NULL,
  user_id int(10) UNSIGNED NOT NULL,
  date_update timestamp NOT NULL DEFAULT current_timestamp(),
  status enum('cart','favorite','pass','expect','cancel') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Структура таблицы purchase_product
--

CREATE TABLE purchase_product (
  id int(10) UNSIGNED NOT NULL,
  purchase_id int(10) UNSIGNED NOT NULL,
  product_id int(10) UNSIGNED NOT NULL,
  price int(10) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Структура таблицы tag
--

CREATE TABLE tag (
  id int(10) UNSIGNED NOT NULL,
  slug varchar(100) NOT NULL,
  name varchar(100) NOT NULL DEFAULT 'Тег',
  logline varchar(255) NOT NULL DEFAULT 'Краткое описание тега',
  type enum('genre','developer','feature') NOT NULL DEFAULT 'genre'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Структура таблицы user
--

CREATE TABLE `user` (
  id int(10) UNSIGNED NOT NULL,
  email varchar(255) NOT NULL,
  nick_name varchar(100) NOT NULL DEFAULT 'Неопознанный_странник',
  password varchar(255) DEFAULT NULL,
  role enum('user','admin') NOT NULL DEFAULT 'user',
  first_name varchar(100) DEFAULT NULL,
  last_name varchar(100) DEFAULT NULL,
  status enum('active','inactive') NOT NULL DEFAULT 'active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Триггеры user
--
DELIMITER $$
CREATE TRIGGER `after_insert_user` AFTER INSERT ON `user` FOR EACH ROW BEGIN
    INSERT INTO purchase (user_id, status)
    VALUES 
    (NEW.id, 'cart'),
    (NEW.id, 'favorite');
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Дублирующая структура для представления user_cart
-- (См. Ниже фактическое представление)
--
CREATE TABLE `user_cart` (
`user_id` int(10) unsigned
,`product_id` int(10) unsigned
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления user_orders
-- (См. Ниже фактическое представление)
--
CREATE TABLE `user_orders` (
`user_id` int(10) unsigned
,`purchase_id` int(10) unsigned
,`date_update` timestamp
,`sum` decimal(32,0)
,`price` int(10) unsigned
,`product_slug` varchar(100)
,`product_name` varchar(100)
,`product_logline` varchar(255)
,`product_image_slug` varchar(255)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления user_products
-- (См. Ниже фактическое представление)
--
CREATE TABLE `user_products` (
`user_id` int(10) unsigned
,`product_name` varchar(100)
,`product_slug` varchar(100)
,`product_logline` varchar(255)
,`product_image_slug` varchar(255)
,`product_file_slug` varchar(255)
,`product_file_version` varchar(50)
,`product_file_description` text
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления user_wishlist
-- (См. Ниже фактическое представление)
--
CREATE TABLE `user_wishlist` (
`user_id` int(10) unsigned
,`product_id` int(10) unsigned
);

-- --------------------------------------------------------

--
-- Структура для представления product_info
--
DROP TABLE IF EXISTS `product_info`;

CREATE ALGORITHM=UNDEFINED DEFINER=root@`%` SQL SECURITY DEFINER VIEW product_info  AS SELECT p.`id` AS `id`, p.slug AS `slug`, p.`name` AS `name`, p.logline AS `logline`, p.current_price AS `current_price`, p.old_price AS `old_price`, p.release_date AS `release_date`, if(timestampdiff(MONTH,p.release_date,current_timestamp()) <= 6,1,0) AS `is_new`, p.product_id AS `product_id`, p.description AS `description`, p.localization AS `localization`, p.requirement AS `requirement`, p.`status` AS `status`, concat('/media/image/card/',p.slug,'.webp') AS `image_card`, concat('/media/image/background/',p.slug,'.webp') AS `image_background`, concat('/media/video/background/',p.slug,'.webm') AS `video_background`, round((p.old_price - p.current_price) * 100 / p.old_price,0) AS `discount` FROM product AS `p` ;

-- --------------------------------------------------------

--
-- Структура для представления product_relevance
--
DROP TABLE IF EXISTS `product_relevance`;

CREATE ALGORITHM=UNDEFINED DEFINER=root@`%` SQL SECURITY DEFINER VIEW product_relevance  AS SELECT p.`id` AS `id`, ifnull((ps.sales - min(ps.sales) over ()) / (max(ps.sales) over () - min(ps.sales) over ()),0) * 0.6 + ifnull((p.release_date - min(p.release_date) over ()) / (max(p.release_date) over () - min(p.release_date) over ()),0) * 0.4 AS `relevance` FROM (product p join product_sales ps on(p.`id` = ps.`id`)) ;

-- --------------------------------------------------------

--
-- Структура для представления product_sales
--
DROP TABLE IF EXISTS `product_sales`;

CREATE ALGORITHM=UNDEFINED DEFINER=root@`%` SQL SECURITY DEFINER VIEW product_sales  AS SELECT p.`id` AS `id`, coalesce(s.sales,0) AS `sales` FROM (product p left join (select pp.product_id AS product_id,count(pp.product_id) AS sales from (purchase_product pp join purchase pur on(pp.purchase_id = pur.`id`)) where pur.`status` = 'pass' group by pp.product_id) s on(p.`id` = s.product_id)) ;

-- --------------------------------------------------------

--
-- Структура для представления user_cart
--
DROP TABLE IF EXISTS `user_cart`;

CREATE ALGORITHM=UNDEFINED DEFINER=root@`%` SQL SECURITY DEFINER VIEW user_cart  AS SELECT u.`id` AS `user_id`, pp.product_id AS `product_id` FROM (((`user` u join purchase p on(u.`id` = p.user_id)) join purchase_product pp on(p.`id` = pp.purchase_id)) join product prod on(pp.product_id = prod.`id`)) WHERE p.`status` = 'cart' ;

-- --------------------------------------------------------

--
-- Структура для представления user_orders
--
DROP TABLE IF EXISTS `user_orders`;

CREATE ALGORITHM=UNDEFINED DEFINER=root@`%` SQL SECURITY DEFINER VIEW user_orders  AS SELECT p.user_id AS `user_id`, p.`id` AS `purchase_id`, p.date_update AS `date_update`, sum(pp.price) over ( partition by p.`id`) AS `sum`, pp.price AS `price`, prod.slug AS `product_slug`, prod.`name` AS `product_name`, prod.logline AS `product_logline`, pf.slug AS `product_image_slug` FROM (((purchase p join purchase_product pp on(p.`id` = pp.purchase_id)) join product prod on(pp.product_id = prod.`id`)) left join product_file pf on(prod.`id` = pf.product_id and pf.`type` = 'image' and pf.subtype = 'card')) WHERE p.`status` in ('pass','expect','cancel') ;

-- --------------------------------------------------------

--
-- Структура для представления user_products
--
DROP TABLE IF EXISTS `user_products`;

CREATE ALGORITHM=UNDEFINED DEFINER=root@`%` SQL SECURITY DEFINER VIEW user_products  AS SELECT u.`id` AS `user_id`, prod.`name` AS `product_name`, prod.slug AS `product_slug`, prod.logline AS `product_logline`, pf_image.slug AS `product_image_slug`, pf_file.slug AS `product_file_slug`, pf_file.version AS `product_file_version`, pf_file.description AS `product_file_description` FROM (((((`user` u join purchase p on(u.`id` = p.user_id)) join purchase_product pp on(p.`id` = pp.purchase_id)) join product prod on(pp.product_id = prod.`id`)) left join product_file pf_image on(prod.`id` = pf_image.product_id and pf_image.`type` = 'image' and pf_image.subtype = 'card')) left join product_file pf_file on(prod.`id` = pf_file.product_id and pf_file.`type` = 'file' and pf_file.subtype = 'product')) WHERE p.`status` = 'pass' ;

-- --------------------------------------------------------

--
-- Структура для представления user_wishlist
--
DROP TABLE IF EXISTS `user_wishlist`;

CREATE ALGORITHM=UNDEFINED DEFINER=root@`%` SQL SECURITY DEFINER VIEW user_wishlist  AS SELECT u.`id` AS `user_id`, pp.product_id AS `product_id` FROM (((`user` u join purchase p on(u.`id` = p.user_id)) join purchase_product pp on(p.`id` = pp.purchase_id)) join product prod on(pp.product_id = prod.`id`)) WHERE p.`status` = 'favorite' ;

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы product
--
ALTER TABLE product
  ADD PRIMARY KEY (id),
  ADD UNIQUE KEY slug (slug),
  ADD KEY product_id (product_id);

--
-- Индексы таблицы product_file
--
ALTER TABLE product_file
  ADD PRIMARY KEY (id),
  ADD UNIQUE KEY product_id (product_id,slug);

--
-- Индексы таблицы product_tag
--
ALTER TABLE product_tag
  ADD PRIMARY KEY (id),
  ADD KEY product_id (product_id,tag_id);

--
-- Индексы таблицы purchase
--
ALTER TABLE purchase
  ADD PRIMARY KEY (id),
  ADD KEY user_id (user_id);

--
-- Индексы таблицы purchase_product
--
ALTER TABLE purchase_product
  ADD PRIMARY KEY (id),
  ADD KEY purchase_id (purchase_id,product_id);

--
-- Индексы таблицы tag
--
ALTER TABLE tag
  ADD PRIMARY KEY (id),
  ADD UNIQUE KEY slug (slug);

--
-- Индексы таблицы user
--
ALTER TABLE user
  ADD PRIMARY KEY (id),
  ADD UNIQUE KEY email (email);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы product
--
ALTER TABLE product
  MODIFY id int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы product_file
--
ALTER TABLE product_file
  MODIFY id int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы product_tag
--
ALTER TABLE product_tag
  MODIFY id int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы purchase
--
ALTER TABLE purchase
  MODIFY id int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы purchase_product
--
ALTER TABLE purchase_product
  MODIFY id int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы tag
--
ALTER TABLE tag
  MODIFY id int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT для таблицы user
--
ALTER TABLE user
  MODIFY id int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы product
--
ALTER TABLE product
  ADD CONSTRAINT product_ibfk_1 FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы product_file
--
ALTER TABLE product_file
  ADD CONSTRAINT product_file_ibfk_1 FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы product_tag
--
ALTER TABLE product_tag
  ADD CONSTRAINT product_tag_ibfk_1 FOREIGN KEY (tag_id) REFERENCES tag (id) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT product_tag_ibfk_2 FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы purchase
--
ALTER TABLE purchase
  ADD CONSTRAINT purchase_ibfk_1 FOREIGN KEY (user_id) REFERENCES `user` (id) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы purchase_product
--
ALTER TABLE purchase_product
  ADD CONSTRAINT purchase_product_ibfk_1 FOREIGN KEY (product_id) REFERENCES product (id) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT purchase_product_ibfk_2 FOREIGN KEY (purchase_id) REFERENCES purchase (id) ON DELETE CASCADE ON UPDATE CASCADE;



CREATE TABLE product (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(100) NOT NULL,
  name VARCHAR(100) NOT NULL,
  logline VARCHAR(255) NOT NULL,
  current_price INT NOT NULL,
  old_price INT DEFAULT NULL,
  release_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  product_id INT UNSIGNED DEFAULT NULL,
  description TEXT NOT NULL,
  localization ENUM('full', 'text') DEFAULT 'full',
  requirement TEXT NOT NULL,
  status ENUM('available', 'not_available') NOT NULL DEFAULT 'available',
  PRIMARY KEY (id),
  UNIQUE KEY (slug),
  FOREIGN KEY (product_id) 
    REFERENCES product(id) 
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

CREATE TABLE product_file (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id INT UNSIGNED NOT NULL,
  slug VARCHAR(255) NOT NULL,
  type ENUM('video', 'image', 'file') NOT NULL,
  subtype ENUM('background', 'card', 'product', 'update') NOT NULL,
  version VARCHAR(50) DEFAULT NULL,
  description TEXT DEFAULT NULL,
  date_add TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY (product_id, slug),
  FOREIGN KEY (product_id) 
    REFERENCES product(id) 
    ON DELETE CASCADE 
    ON UPDATE CASCADE
);

CREATE TABLE user (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  nick_name VARCHAR(100) NOT NULL,
  password VARCHAR(255) DEFAULT NULL,
  role ENUM('user', 'admin') NOT NULL DEFAULT 'user',
  first_name VARCHAR(100) DEFAULT NULL,
  last_name VARCHAR(100) DEFAULT NULL,
  status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
  PRIMARY KEY (id),
  UNIQUE KEY (email)
);

CREATE TABLE purchase (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  date_update TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('cart', 'favorite', 'pass', 'expect', 'cancel') NOT NULL,
  PRIMARY KEY (id),
  INDEX (user_id),
  FOREIGN KEY (user_id) 
    REFERENCES user(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE purchase_product (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  purchase_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  price INT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY (purchase_id, product_id),
  FOREIGN KEY (purchase_id) 
    REFERENCES purchase(id) 
    ON DELETE CASCADE 
    ON UPDATE CASCADE,
  FOREIGN KEY (product_id) 
    REFERENCES product(id) 
    ON DELETE CASCADE 
    ON UPDATE CASCADE
);

CREATE TABLE tag (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(100) NOT NULL,
  name VARCHAR(100) NOT NULL,
  logline VARCHAR(255) NOT NULL,
  type ENUM('genre', 'developer', 'feature') NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY (slug)
);

CREATE TABLE product_tag (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id INT UNSIGNED NOT NULL,
  tag_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY (product_id, tag_id),
  FOREIGN KEY (product_id) 
    REFERENCES product(id) 
    ON DELETE CASCADE 
    ON UPDATE CASCADE,
  FOREIGN KEY (tag_id) 
    REFERENCES tag(id) 
    ON DELETE CASCADE 
    ON UPDATE CASCADE
);


--------------------------------------------------------------------------


DELIMITER $$
CREATE TRIGGER after_insert_user 
AFTER INSERT ON user 
FOR EACH ROW 
BEGIN
  INSERT INTO purchase(user_id, status) 
  VALUES (NEW.id, 'cart'), (NEW.id, 'favorite');
END$$


CREATE PROCEDURE purchase_expect(
  IN p_purchase_id INT UNSIGNED, 
  IN is_pass BOOLEAN
)
BEGIN
  IF NOT EXISTS(
    SELECT 1 
    FROM purchase 
    WHERE id = p_purchase_id 
      AND status = 'expect'
  ) THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Статус заказа не ожидает подтверждения';
  END IF;

  UPDATE purchase 
  SET status = IF(is_pass, 'pass', 'cancel') 
  WHERE id = p_purchase_id;
END$$


CREATE PROCEDURE purchase_add(
  IN p_user_id INT UNSIGNED, 
  IN p_product_id INT UNSIGNED, 
  IN type_cart BOOLEAN
)
BEGIN
  DECLARE p_purchase_id INT UNSIGNED;
  DECLARE purchase_type ENUM('cart', 'favorite');

  SET purchase_type = IF(type_cart = 1, 'cart', 'favorite');

  SELECT id INTO p_purchase_id 
  FROM purchase 
  WHERE user_id = p_user_id 
    AND status = purchase_type 
  LIMIT 1;

  IF p_purchase_id IS NULL THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Не удается найти корзину/избранное';
  END IF;

  IF EXISTS(
    SELECT 1 
    FROM purchase_product 
    WHERE purchase_id = p_purchase_id 
      AND product_id = p_product_id
  ) THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Товар уже добавлен';
  END IF;

  INSERT INTO purchase_product (purchase_id, product_id) 
  VALUES (p_purchase_id, p_product_id);
END$$


CREATE PROCEDURE purchase_delete(
  IN p_user_id INT UNSIGNED, 
  IN p_product_id INT UNSIGNED, 
  IN type_cart BOOLEAN
)
BEGIN
  DECLARE p_purchase_id INT UNSIGNED;
  DECLARE purchase_type ENUM('cart', 'favorite');

  SET purchase_type = IF(type_cart = 1, 'cart', 'favorite');

  SELECT id INTO p_purchase_id 
  FROM purchase 
  WHERE user_id = p_user_id 
    AND status = purchase_type 
  LIMIT 1;

  IF p_purchase_id IS NULL THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Корзина/избранное не найдены';
  END IF;

  IF NOT EXISTS(
    SELECT 1 
    FROM purchase_product 
    WHERE purchase_id = p_purchase_id 
      AND product_id = p_product_id
  ) THEN
      SIGNAL SQLSTATE '45000' 
      SET MESSAGE_TEXT = 'Товар отсутствует';
  END IF;

  DELETE FROM purchase_product 
  WHERE purchase_id = p_purchase_id 
    AND product_id = p_product_id;
END$$


CREATE PROCEDURE purchase_cart(IN p_user_id INT UNSIGNED)
BEGIN
  DECLARE p_purchase_id INT UNSIGNED;

  SELECT id INTO p_purchase_id 
  FROM purchase 
  WHERE user_id = p_user_id 
    AND status = 'cart' 
  LIMIT 1;

  IF p_purchase_id IS NULL THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Корзина не найдена';
  END IF;

  IF NOT EXISTS(
    SELECT 1 
    FROM purchase_product 
    WHERE purchase_id = p_purchase_id
  ) THEN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Корзина пуста';
  END IF;

  UPDATE purchase 
  SET status = 'expect' 
  WHERE id = p_purchase_id;

  UPDATE purchase_product pp 
  JOIN product p ON pp.product_id = p.id 
  SET pp.price = p.current_price 
  WHERE pp.purchase_id = p_purchase_id;

  INSERT INTO purchase (user_id, status) 
  VALUES (p_user_id, 'cart');
END$$

CREATE PROCEDURE user_games(IN p_user_id INT UNSIGNED)
BEGIN
  SELECT p.id AS product_id, pur.date_update AS date_purchase
  FROM product p
  JOIN purchase_product pp ON p.id = pp.product_id
  JOIN purchase pur ON pp.purchase_id = pur.id
  WHERE pur.user_id = p_user_id 
    AND pur.status = 'pass';
END$$


CREATE PROCEDURE user_orders(IN p_user_id INT UNSIGNED)
BEGIN
  SELECT pur.id AS purchase_id,
    p.id AS product_id, 
    pp.price
  FROM product p
  JOIN purchase_product pp ON p.id = pp.product_id
  JOIN purchase pur ON pp.purchase_id = pur.id
  WHERE pur.user_id = p_user_id 
    AND pur.status IN ('pass','expect','cancel');
END$$

DELIMITER ;

CREATE VIEW product_sales AS 
SELECT 
  p.id AS id,
  COALESCE(s.sales, 0) AS sales
FROM product p
LEFT JOIN (
  SELECT pp.product_id, COUNT(pp.product_id) AS sales
  FROM purchase_product pp
  JOIN purchase pur ON pp.purchase_id = pur.id
  WHERE pur.status = 'pass'
  GROUP BY pp.product_id
) s ON p.id = s.product_id;

CREATE VIEW product_relevance AS 
SELECT 
  p.id AS id,
  (
    COALESCE((ps.sales - MIN(ps.sales) OVER ()) / (MAX(ps.sales) OVER () - MIN(ps.sales) OVER ()), 0) * 0.6 
    + 
    COALESCE((UNIX_TIMESTAMP(p.release_date) - MIN(UNIX_TIMESTAMP(p.release_date)) OVER ()) / (MAX(UNIX_TIMESTAMP(p.release_date)) OVER () - MIN(UNIX_TIMESTAMP(p.release_date)) OVER ()), 0) * 0.4
  ) AS relevance
FROM product p
LEFT JOIN product_sales ps ON p.id = ps.id;

CREATE VIEW product_info AS
SELECT 
  p.id AS id,
  p.slug AS slug,
  p.name AS name,
  p.logline AS logline,
  p.current_price AS current_price,
  p.old_price AS old_price,
  p.release_date AS release_date,
  p.product_id AS product_id,
  p.description AS description,
  p.localization AS localization,
  p.requirement AS requirement,
  p.status AS status,
  CONCAT('/media/image/card/', pf_card.slug, '.webp') AS image_card,
  CONCAT('/media/image/background/', pf_background.slug, '.webp') AS image_background,
  CONCAT('/media/video/background/', pf_video.slug, '.webm') AS video_background,
  ROUND((p.old_price - p.current_price) * 100 / p.old_price, 0) AS discount,
  IF(TIMESTAMPDIFF(MONTH, p.release_date, CURRENT_TIMESTAMP()) <= 6, 1, 0) AS is_new
FROM 
  product p
LEFT JOIN 
  product_file pf_card 
  ON p.id = pf_card.product_id 
  AND pf_card.type = 'image' 
  AND pf_card.subtype = 'card'
LEFT JOIN 
  product_file pf_background 
  ON p.id = pf_background.product_id 
  AND pf_background.type = 'image' 
  AND pf_background.subtype = 'background'
LEFT JOIN 
  product_file pf_video 
  ON p.id = pf_video.product_id 
  AND pf_video.type = 'video' 
  AND pf_video.subtype = 'background';

mysql -h MariaDB-11.2 -u root -p
USE shop;

INSERT INTO user (email, nick_name) VALUES ('21@example.com', '21');
SELECT * FROM purchase WHERE user_id = LAST_INSERT_ID();

CALL purchase_add(21, 1, TRUE);
SELECT * FROM purchase p inner join purchase_product pp on p.id = pp.purchase_id WHERE p.user_id = 21;


CALL purchase_cart(21);
SELECT * FROM purchase p WHERE p.user_id = 21;

CALL purchase_expect(21, TRUE);
SELECT * FROM product_relevance ORDER BY relevance DESC;
