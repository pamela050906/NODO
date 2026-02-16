CREATE TABLE public.clientes (
    id integer NOT NULL,
    nombre character varying(200) NOT NULL,
    rfc character varying(13),
    telefono character varying(15),
    email character varying(150),
    direccion text,
    limite_credito numeric(12,2) DEFAULT 0,
    activo boolean DEFAULT true,
    creado_en timestamp without time zone DEFAULT now()
);

CREATE TABLE public.cuentas_por_cobrar (
    id integer NOT NULL,
    venta_id integer NOT NULL,
    cliente_id integer NOT NULL,
    monto_total numeric(12,2) NOT NULL,
    monto_pagado numeric(12,2) DEFAULT 0,
    saldo_pendiente numeric(12,2) NOT NULL,
    fecha_vencimiento date,
    estado character varying(20) DEFAULT 'PENDIENTE'::character varying,
    creada_en timestamp without time zone DEFAULT now(),
    CONSTRAINT cuentas_estado_check CHECK (((estado)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'PAGADA'::character varying, 'VENCIDA'::character varying])::text[]))),
    CONSTRAINT cuentas_saldo_check CHECK ((saldo_pendiente >= (0)::numeric))
);

CREATE TABLE public.factura_ventas (
    factura_id integer NOT NULL,
    venta_id integer NOT NULL
);

CREATE TABLE public.facturas (
    id integer NOT NULL,
    uuid_sat character varying(50),
    fecha timestamp without time zone,
    total numeric(12,2),
    rfc_emisor character varying(13) NOT NULL,
    rfc_receptor character varying(13),
    creada_en timestamp without time zone DEFAULT now(),
    serie character varying(10),
    folio integer,
    uso_cfdi character varying(10),
    forma_pago character varying(10),
    metodo_pago character varying(10),
    estado character varying(20) DEFAULT 'BORRADOR'::character varying,
    xml_content text,
    xml_url character varying(500),
    pdf_url character varying(500)
);

CREATE TABLE public.folios_sat (
    id integer NOT NULL,
    serie character varying(10),
    folio_actual integer NOT NULL,
    activo boolean DEFAULT true
);

CREATE TABLE public.inventario (
    id integer NOT NULL,
    variante_id integer NOT NULL,
    stock integer NOT NULL,
    actualizado_en timestamp without time zone DEFAULT now(),
    CONSTRAINT inventario_stock_check CHECK ((stock >= 0))
);

CREATE TABLE public.movimientos_inventario (
    id integer NOT NULL,
    variante_id integer NOT NULL,
    tipo character varying(20) NOT NULL,
    cantidad integer NOT NULL,
    referencia text,
    creado_en timestamp without time zone DEFAULT now(),
    CONSTRAINT movimientos_inventario_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT movimientos_inventario_tipo_check CHECK (((tipo)::text = ANY (ARRAY[('ENTRADA'::character varying)::text, ('SALIDA'::character varying)::text, ('AJUSTE'::character varying)::text])))
);

CREATE TABLE public.pagos_cuenta (
    id integer NOT NULL,
    cuenta_id integer NOT NULL,
    monto numeric(12,2) NOT NULL,
    metodo_pago character varying(20) NOT NULL,
    referencia character varying(100),
    notas text,
    usuario_id integer,
    creado_en timestamp without time zone DEFAULT now(),
    CONSTRAINT pagos_metodo_check CHECK (((metodo_pago)::text = ANY ((ARRAY['EFECTIVO'::character varying, 'TARJETA'::character varying, 'TRANSFERENCIA'::character varying, 'CHEQUE'::character varying])::text[]))),
    CONSTRAINT pagos_monto_check CHECK ((monto > (0)::numeric))
);

CREATE TABLE public.productos (
    id integer NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true,
    creado_en timestamp without time zone DEFAULT now(),
    categoria character varying(100),
    marca character varying(100),
    actualizado_en timestamp without time zone DEFAULT now()
);

CREATE TABLE public.puntos_venta (
    id integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true
);

CREATE TABLE public.roles (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL
);

CREATE TABLE public.tickets (
    id integer NOT NULL,
    venta_id integer NOT NULL,
    contenido text,
    creado_en timestamp without time zone DEFAULT now()
);

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    password_hash text NOT NULL,
    rol_id integer NOT NULL,
    activo boolean DEFAULT true,
    creado_en timestamp without time zone DEFAULT now()
);

CREATE TABLE public.variantes_producto (
    id integer NOT NULL,
    producto_id integer NOT NULL,
    sku character varying(50) NOT NULL,
    talla character varying(20),
    color character varying(30),
    precio_menudeo numeric(10,2) NOT NULL,
    precio_mayoreo numeric(10,2) NOT NULL,
    codigo_barras character varying(100) NOT NULL,
    activo boolean DEFAULT true,
    CONSTRAINT variantes_producto_precio_mayoreo_check CHECK ((precio_mayoreo >= (0)::numeric)),
    CONSTRAINT variantes_producto_precio_menudeo_check CHECK ((precio_menudeo >= (0)::numeric))
);

CREATE TABLE public.venta_detalle (
    id integer NOT NULL,
    venta_id integer NOT NULL,
    variante_id integer NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    CONSTRAINT venta_detalle_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT venta_detalle_precio_unitario_check CHECK ((precio_unitario >= (0)::numeric)),
    CONSTRAINT venta_detalle_subtotal_check CHECK ((subtotal >= (0)::numeric))
);

CREATE TABLE public.ventas (
    id integer NOT NULL,
    punto_venta_id integer NOT NULL,
    usuario_id integer NOT NULL,
    total numeric(12,2) NOT NULL,
    metodo_pago character varying(20) NOT NULL,
    creada_en timestamp without time zone DEFAULT now(),
    subtotal numeric(12,2) DEFAULT 0,
    descuento numeric(12,2) DEFAULT 0,
    impuesto numeric(12,2) DEFAULT 0,
    estado character varying(20) DEFAULT 'ABIERTA'::character varying,
    completed_at timestamp without time zone,
    cliente_id integer,
    tipo_venta character varying(20) DEFAULT 'CONTADO'::character varying,
    CONSTRAINT ventas_descuento_check CHECK ((descuento >= (0)::numeric)),
    CONSTRAINT ventas_estado_check CHECK (((estado)::text = ANY ((ARRAY['ABIERTA'::character varying, 'CERRADA'::character varying, 'CANCELADA'::character varying])::text[]))),
    CONSTRAINT ventas_impuesto_check CHECK ((impuesto >= (0)::numeric)),
    CONSTRAINT ventas_metodo_pago_check CHECK (((metodo_pago)::text = ANY (ARRAY[('EFECTIVO'::character varying)::text, ('TARJETA'::character varying)::text]))),
    CONSTRAINT ventas_subtotal_check CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT ventas_tipo_venta_check CHECK (((tipo_venta)::text = ANY ((ARRAY['CONTADO'::character varying, 'CREDITO'::character varying])::text[]))),
    CONSTRAINT ventas_total_check CHECK ((total >= (0)::numeric))
);

CREATE INDEX idx_cuentas_cliente ON public.cuentas_por_cobrar USING btree (cliente_id);

CREATE INDEX idx_cuentas_estado ON public.cuentas_por_cobrar USING btree (estado);

CREATE INDEX idx_cuentas_vencimiento ON public.cuentas_por_cobrar USING btree (fecha_vencimiento);

CREATE INDEX idx_facturas_estado ON public.facturas USING btree (estado);

CREATE INDEX idx_facturas_fecha ON public.facturas USING btree (fecha);

CREATE UNIQUE INDEX idx_facturas_uuid_sat ON public.facturas USING btree (uuid_sat);

CREATE INDEX idx_pagos_cuenta ON public.pagos_cuenta USING btree (cuenta_id);

CREATE INDEX idx_ventas_cliente ON public.ventas USING btree (cliente_id);

CREATE INDEX idx_ventas_estado ON public.ventas USING btree (estado);

CREATE INDEX idx_ventas_fecha ON public.ventas USING btree (creada_en);

CREATE INDEX idx_ventas_fecha_estado ON public.ventas USING btree (creada_en, estado);

-- Primary keys (para que dbdiagram.io reconozca PKs si no están inline)
ALTER TABLE public.clientes ADD CONSTRAINT clientes_pkey PRIMARY KEY (id);
ALTER TABLE public.cuentas_por_cobrar ADD CONSTRAINT cuentas_por_cobrar_pkey PRIMARY KEY (id);
ALTER TABLE public.factura_ventas ADD CONSTRAINT factura_ventas_pkey PRIMARY KEY (factura_id, venta_id);
ALTER TABLE public.facturas ADD CONSTRAINT facturas_pkey PRIMARY KEY (id);
ALTER TABLE public.folios_sat ADD CONSTRAINT folios_sat_pkey PRIMARY KEY (id);
ALTER TABLE public.inventario ADD CONSTRAINT inventario_pkey PRIMARY KEY (id);
ALTER TABLE public.movimientos_inventario ADD CONSTRAINT movimientos_inventario_pkey PRIMARY KEY (id);
ALTER TABLE public.pagos_cuenta ADD CONSTRAINT pagos_cuenta_pkey PRIMARY KEY (id);
ALTER TABLE public.productos ADD CONSTRAINT productos_pkey PRIMARY KEY (id);
ALTER TABLE public.puntos_venta ADD CONSTRAINT puntos_venta_pkey PRIMARY KEY (id);
ALTER TABLE public.roles ADD CONSTRAINT roles_pkey PRIMARY KEY (id);
ALTER TABLE public.tickets ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);
ALTER TABLE public.usuarios ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);
ALTER TABLE public.variantes_producto ADD CONSTRAINT variantes_producto_pkey PRIMARY KEY (id);
ALTER TABLE public.venta_detalle ADD CONSTRAINT venta_detalle_pkey PRIMARY KEY (id);
ALTER TABLE public.ventas ADD CONSTRAINT ventas_pkey PRIMARY KEY (id);

-- Foreign keys (relaciones entre tablas)
ALTER TABLE public.cuentas_por_cobrar ADD CONSTRAINT cuentas_por_cobrar_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);
ALTER TABLE public.cuentas_por_cobrar ADD CONSTRAINT cuentas_por_cobrar_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES public.ventas(id);
ALTER TABLE public.factura_ventas ADD CONSTRAINT factura_ventas_factura_id_fkey FOREIGN KEY (factura_id) REFERENCES public.facturas(id) ON DELETE CASCADE;
ALTER TABLE public.factura_ventas ADD CONSTRAINT factura_ventas_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES public.ventas(id) ON DELETE CASCADE;
ALTER TABLE public.inventario ADD CONSTRAINT inventario_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.variantes_producto(id);
ALTER TABLE public.movimientos_inventario ADD CONSTRAINT movimientos_inventario_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.variantes_producto(id);
ALTER TABLE public.pagos_cuenta ADD CONSTRAINT pagos_cuenta_cuenta_id_fkey FOREIGN KEY (cuenta_id) REFERENCES public.cuentas_por_cobrar(id);
ALTER TABLE public.pagos_cuenta ADD CONSTRAINT pagos_cuenta_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);
ALTER TABLE public.tickets ADD CONSTRAINT tickets_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES public.ventas(id);
ALTER TABLE public.usuarios ADD CONSTRAINT usuarios_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id);
ALTER TABLE public.variantes_producto ADD CONSTRAINT variantes_producto_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.productos(id) ON DELETE CASCADE;
ALTER TABLE public.venta_detalle ADD CONSTRAINT venta_detalle_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.variantes_producto(id);
ALTER TABLE public.venta_detalle ADD CONSTRAINT venta_detalle_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES public.ventas(id) ON DELETE CASCADE;
ALTER TABLE public.ventas ADD CONSTRAINT ventas_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);
ALTER TABLE public.ventas ADD CONSTRAINT ventas_punto_venta_id_fkey FOREIGN KEY (punto_venta_id) REFERENCES public.puntos_venta(id);
ALTER TABLE public.ventas ADD CONSTRAINT ventas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);