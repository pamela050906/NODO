--
-- PostgreSQL database dump
--

\restrict hMdBS6ZSRx7xYFqVt8KhkRheBTAGSlrNpmVTJ89ytRbVIMXJSB1m5gcaLQN6bcX

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-02-09 09:46:02

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 278 (class 1255 OID 24905)
-- Name: fn_actualizar_cuenta_pago(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_actualizar_cuenta_pago() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_saldo_nuevo NUMERIC(12,2);
BEGIN
    -- Actualizar monto pagado y saldo
    UPDATE cuentas_por_cobrar
    SET monto_pagado = monto_pagado + NEW.monto,
        saldo_pendiente = saldo_pendiente - NEW.monto
    WHERE id = NEW.cuenta_id;
    
    -- Obtener nuevo saldo
    SELECT saldo_pendiente INTO v_saldo_nuevo
    FROM cuentas_por_cobrar
    WHERE id = NEW.cuenta_id;
    
    -- Actualizar estado si está pagada completamente
    IF v_saldo_nuevo <= 0 THEN
        UPDATE cuentas_por_cobrar
        SET estado = 'PAGADA',
            saldo_pendiente = 0
        WHERE id = NEW.cuenta_id;
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_actualizar_cuenta_pago() OWNER TO postgres;

--
-- TOC entry 263 (class 1255 OID 25040)
-- Name: fn_calcular_totales_factura(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_calcular_totales_factura(p_factura_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_subtotal NUMERIC(16,2);
    v_descuento NUMERIC(16,2);
    v_iva_trasladado NUMERIC(16,2);
    v_iva_retenido NUMERIC(16,2);
    v_ieps_trasladado NUMERIC(16,2);
    v_isr_retenido NUMERIC(16,2);
    v_total NUMERIC(16,2);
BEGIN
    -- Calcular subtotal
    SELECT COALESCE(SUM(importe), 0)
    INTO v_subtotal
    FROM factura_conceptos
    WHERE factura_id = p_factura_id;
    
    -- Calcular descuento total
    SELECT COALESCE(SUM(descuento), 0)
    INTO v_descuento
    FROM factura_conceptos
    WHERE factura_id = p_factura_id;
    
    -- Calcular IVA trasladado
    SELECT COALESCE(SUM(fci.importe), 0)
    INTO v_iva_trasladado
    FROM factura_conceptos fc
    JOIN factura_concepto_impuestos fci ON fc.id = fci.concepto_id
    WHERE fc.factura_id = p_factura_id
    AND fci.tipo_movimiento = 'TRASLADO'
    AND fci.impuesto = '002';
    
    -- Calcular IVA retenido
    SELECT COALESCE(SUM(fci.importe), 0)
    INTO v_iva_retenido
    FROM factura_conceptos fc
    JOIN factura_concepto_impuestos fci ON fc.id = fci.concepto_id
    WHERE fc.factura_id = p_factura_id
    AND fci.tipo_movimiento = 'RETENCION'
    AND fci.impuesto = '002';
    
    -- Calcular IEPS trasladado
    SELECT COALESCE(SUM(fci.importe), 0)
    INTO v_ieps_trasladado
    FROM factura_conceptos fc
    JOIN factura_concepto_impuestos fci ON fc.id = fci.concepto_id
    WHERE fc.factura_id = p_factura_id
    AND fci.tipo_movimiento = 'TRASLADO'
    AND fci.impuesto = '003';
    
    -- Calcular ISR retenido
    SELECT COALESCE(SUM(fci.importe), 0)
    INTO v_isr_retenido
    FROM factura_conceptos fc
    JOIN factura_concepto_impuestos fci ON fc.id = fci.concepto_id
    WHERE fc.factura_id = p_factura_id
    AND fci.tipo_movimiento = 'RETENCION'
    AND fci.impuesto = '001';
    
    -- Calcular total
    v_total := v_subtotal - v_descuento + v_iva_trasladado - v_iva_retenido + v_ieps_trasladado - v_isr_retenido;
    
    -- Actualizar factura
    UPDATE facturas
    SET 
        subtotal = v_subtotal,
        descuento = v_descuento,
        iva_trasladado = v_iva_trasladado,
        iva_retenido = v_iva_retenido,
        ieps_trasladado = v_ieps_trasladado,
        isr_retenido = v_isr_retenido,
        total = v_total
    WHERE id = p_factura_id;
END;
$$;


ALTER FUNCTION public.fn_calcular_totales_factura(p_factura_id integer) OWNER TO postgres;

--
-- TOC entry 5348 (class 0 OID 0)
-- Dependencies: 263
-- Name: FUNCTION fn_calcular_totales_factura(p_factura_id integer); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_calcular_totales_factura(p_factura_id integer) IS 'Recalcula todos los totales e impuestos de una factura';


--
-- TOC entry 260 (class 1255 OID 24809)
-- Name: fn_descuento_inventario(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_descuento_inventario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    stock_actual INT;
BEGIN
    SELECT stock INTO stock_actual
    FROM inventario
    WHERE variante_id = NEW.variante_id
    FOR UPDATE;

    IF stock_actual IS NULL THEN
        RAISE EXCEPTION 'No existe inventario para la variante %', NEW.variante_id;
    END IF;

    IF stock_actual < NEW.cantidad THEN
        RAISE EXCEPTION 'Inventario insuficiente para la variante %', NEW.variante_id;
    END IF;

    UPDATE inventario
    SET stock = stock - NEW.cantidad,
        actualizado_en = NOW()
    WHERE variante_id = NEW.variante_id;

    INSERT INTO movimientos_inventario (
        variante_id, tipo, cantidad, referencia
    ) VALUES (
        NEW.variante_id,
        'SALIDA',
        NEW.cantidad,
        'Venta ID ' || NEW.venta_id
    );

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_descuento_inventario() OWNER TO postgres;

--
-- TOC entry 261 (class 1255 OID 24811)
-- Name: fn_precio_automatico(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_precio_automatico() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_precio NUMERIC(10,2);
BEGIN
    SELECT
        CASE
            WHEN NEW.cantidad >= 12 THEN precio_mayoreo
            ELSE precio_menudeo
        END
    INTO v_precio
    FROM variantes_producto
    WHERE id = NEW.variante_id;

    IF v_precio IS NULL THEN
        RAISE EXCEPTION
        'Precio no definido para variante_id %', NEW.variante_id;
    END IF;

    NEW.precio_unitario := v_precio;
    NEW.subtotal := v_precio * NEW.cantidad;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_precio_automatico() OWNER TO postgres;

--
-- TOC entry 276 (class 1255 OID 24827)
-- Name: fn_precio_automatico_acumulado(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_precio_automatico_acumulado() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_precio_menudeo NUMERIC(10,2);
    v_precio_mayoreo NUMERIC(10,2);
    v_cantidad_total INTEGER;
    v_precio_aplicar NUMERIC(10,2);
BEGIN
    -- Obtener precios de la variante
    SELECT precio_menudeo, precio_mayoreo
    INTO v_precio_menudeo, v_precio_mayoreo
    FROM variantes_producto
    WHERE id = NEW.variante_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Variante % no encontrada', NEW.variante_id;
    END IF;

    -- Calcular cantidad total acumulada de esta variante en la venta
    SELECT COALESCE(SUM(cantidad), 0) + NEW.cantidad
    INTO v_cantidad_total
    FROM venta_detalle
    WHERE venta_id = NEW.venta_id
    AND variante_id = NEW.variante_id;

    -- Aplicar precio según cantidad acumulada
    IF v_cantidad_total >= 12 THEN
        v_precio_aplicar := v_precio_mayoreo;
        
        -- IMPORTANTE: Actualizar TODOS los detalles de esta variante en la venta
        -- para que tengan el precio de mayoreo
        UPDATE venta_detalle
        SET precio_unitario = v_precio_mayoreo,
            subtotal = cantidad * v_precio_mayoreo
        WHERE venta_id = NEW.venta_id
        AND variante_id = NEW.variante_id;
    ELSE
        v_precio_aplicar := v_precio_menudeo;
    END IF;

    -- Asignar precio al nuevo detalle
    NEW.precio_unitario := v_precio_aplicar;
    NEW.subtotal := NEW.cantidad * v_precio_aplicar;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_precio_automatico_acumulado() OWNER TO postgres;

--
-- TOC entry 5349 (class 0 OID 0)
-- Dependencies: 276
-- Name: FUNCTION fn_precio_automatico_acumulado(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_precio_automatico_acumulado() IS 'Aplica precio mayoreo cuando cantidad acumulada de un producto en la venta >= 12';


--
-- TOC entry 277 (class 1255 OID 24829)
-- Name: fn_recalcular_totales_venta(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_recalcular_totales_venta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_subtotal NUMERIC(12,2);
    v_total NUMERIC(12,2);
BEGIN
    -- Calcular subtotal sumando todos los detalles
    SELECT COALESCE(SUM(subtotal), 0)
    INTO v_subtotal
    FROM venta_detalle
    WHERE venta_id = COALESCE(NEW.venta_id, OLD.venta_id);

    -- Por ahora total = subtotal (sin descuentos ni impuestos)
    v_total := v_subtotal;

    -- Actualizar venta
    UPDATE ventas
    SET subtotal = v_subtotal,
        total = v_total
    WHERE id = COALESCE(NEW.venta_id, OLD.venta_id);

    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION public.fn_recalcular_totales_venta() OWNER TO postgres;

--
-- TOC entry 5350 (class 0 OID 0)
-- Dependencies: 277
-- Name: FUNCTION fn_recalcular_totales_venta(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_recalcular_totales_venta() IS 'Recalcula automáticamente subtotal y total de la venta';


--
-- TOC entry 262 (class 1255 OID 24815)
-- Name: fn_validar_stock(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_validar_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_stock_actual INTEGER;
BEGIN
    -- Bloquea la fila de inventario
    SELECT stock
    INTO v_stock_actual
    FROM inventario
    WHERE variante_id = NEW.variante_id
    FOR UPDATE;

    IF v_stock_actual IS NULL THEN
        RAISE EXCEPTION 'No existe inventario para variante_id %', NEW.variante_id;
    END IF;

    IF v_stock_actual < NEW.cantidad THEN
        RAISE EXCEPTION
        'Stock insuficiente. Disponible: %, solicitado: %',
        v_stock_actual, NEW.cantidad;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_validar_stock() OWNER TO postgres;

--
-- TOC entry 264 (class 1255 OID 25041)
-- Name: trg_recalcular_totales_factura(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_recalcular_totales_factura() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM fn_calcular_totales_factura(
        CASE 
            WHEN TG_OP = 'DELETE' THEN OLD.factura_id
            ELSE NEW.factura_id
        END
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_recalcular_totales_factura() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 245 (class 1259 OID 24832)
-- Name: clientes; Type: TABLE; Schema: public; Owner: postgres
--

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


ALTER TABLE public.clientes OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 24831)
-- Name: clientes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clientes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.clientes_id_seq OWNER TO postgres;

--
-- TOC entry 5351 (class 0 OID 0)
-- Dependencies: 244
-- Name: clientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clientes_id_seq OWNED BY public.clientes.id;


--
-- TOC entry 251 (class 1259 OID 24921)
-- Name: configuracion_fiscal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configuracion_fiscal (
    id integer NOT NULL,
    rfc_emisor character varying(13) NOT NULL,
    nombre_emisor character varying(255) NOT NULL,
    razon_social character varying(255) NOT NULL,
    regimen_fiscal character varying(10) NOT NULL,
    calle character varying(100),
    numero_exterior character varying(20),
    numero_interior character varying(20),
    colonia character varying(100),
    localidad character varying(100),
    municipio character varying(100),
    estado character varying(100),
    pais character varying(100) DEFAULT 'México'::character varying,
    codigo_postal character varying(5) NOT NULL,
    certificado_cer bytea,
    certificado_key bytea,
    certificado_password character varying(255),
    no_certificado character varying(50),
    vigencia_desde date,
    vigencia_hasta date,
    activo boolean DEFAULT true,
    creado_en timestamp without time zone DEFAULT now(),
    actualizado_en timestamp without time zone DEFAULT now(),
    CONSTRAINT check_codigo_postal CHECK (((codigo_postal)::text ~ '^\d{5}$'::text))
);


ALTER TABLE public.configuracion_fiscal OWNER TO postgres;

--
-- TOC entry 5352 (class 0 OID 0)
-- Dependencies: 251
-- Name: TABLE configuracion_fiscal; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.configuracion_fiscal IS 'Configuración fiscal de la empresa emisora de facturas';


--
-- TOC entry 5353 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN configuracion_fiscal.regimen_fiscal; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.configuracion_fiscal.regimen_fiscal IS 'Código SAT del régimen fiscal (601, 603, 612, 621, 625, 626)';


--
-- TOC entry 5354 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN configuracion_fiscal.certificado_cer; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.configuracion_fiscal.certificado_cer IS 'Certificado .cer del SAT (archivo binario)';


--
-- TOC entry 5355 (class 0 OID 0)
-- Dependencies: 251
-- Name: COLUMN configuracion_fiscal.certificado_key; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.configuracion_fiscal.certificado_key IS 'Llave privada .key del SAT (archivo binario)';


--
-- TOC entry 250 (class 1259 OID 24920)
-- Name: configuracion_fiscal_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.configuracion_fiscal_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.configuracion_fiscal_id_seq OWNER TO postgres;

--
-- TOC entry 5356 (class 0 OID 0)
-- Dependencies: 250
-- Name: configuracion_fiscal_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.configuracion_fiscal_id_seq OWNED BY public.configuracion_fiscal.id;


--
-- TOC entry 247 (class 1259 OID 24846)
-- Name: cuentas_por_cobrar; Type: TABLE; Schema: public; Owner: postgres
--

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


ALTER TABLE public.cuentas_por_cobrar OWNER TO postgres;

--
-- TOC entry 5357 (class 0 OID 0)
-- Dependencies: 247
-- Name: TABLE cuentas_por_cobrar; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.cuentas_por_cobrar IS 'Cuentas por cobrar de ventas a crédito';


--
-- TOC entry 246 (class 1259 OID 24845)
-- Name: cuentas_por_cobrar_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cuentas_por_cobrar_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cuentas_por_cobrar_id_seq OWNER TO postgres;

--
-- TOC entry 5358 (class 0 OID 0)
-- Dependencies: 246
-- Name: cuentas_por_cobrar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cuentas_por_cobrar_id_seq OWNED BY public.cuentas_por_cobrar.id;


--
-- TOC entry 255 (class 1259 OID 24985)
-- Name: factura_concepto_impuestos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.factura_concepto_impuestos (
    id integer NOT NULL,
    concepto_id integer NOT NULL,
    tipo_movimiento character varying(10) NOT NULL,
    base numeric(16,2) NOT NULL,
    impuesto character varying(10) NOT NULL,
    tipo_factor character varying(10) NOT NULL,
    tasa_o_cuota numeric(8,6) NOT NULL,
    importe numeric(16,2) NOT NULL,
    CONSTRAINT check_impuesto CHECK (((impuesto)::text = ANY ((ARRAY['001'::character varying, '002'::character varying, '003'::character varying])::text[]))),
    CONSTRAINT check_tipo_factor CHECK (((tipo_factor)::text = ANY ((ARRAY['Tasa'::character varying, 'Cuota'::character varying, 'Exento'::character varying])::text[]))),
    CONSTRAINT check_tipo_movimiento CHECK (((tipo_movimiento)::text = ANY ((ARRAY['TRASLADO'::character varying, 'RETENCION'::character varying])::text[])))
);


ALTER TABLE public.factura_concepto_impuestos OWNER TO postgres;

--
-- TOC entry 5359 (class 0 OID 0)
-- Dependencies: 255
-- Name: TABLE factura_concepto_impuestos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.factura_concepto_impuestos IS 'Impuestos trasladados y retenidos por concepto';


--
-- TOC entry 5360 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN factura_concepto_impuestos.impuesto; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.factura_concepto_impuestos.impuesto IS '001=ISR, 002=IVA, 003=IEPS';


--
-- TOC entry 5361 (class 0 OID 0)
-- Dependencies: 255
-- Name: COLUMN factura_concepto_impuestos.tipo_factor; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.factura_concepto_impuestos.tipo_factor IS 'Tasa (porcentaje), Cuota (cantidad fija), Exento';


--
-- TOC entry 254 (class 1259 OID 24984)
-- Name: factura_concepto_impuestos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.factura_concepto_impuestos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.factura_concepto_impuestos_id_seq OWNER TO postgres;

--
-- TOC entry 5362 (class 0 OID 0)
-- Dependencies: 254
-- Name: factura_concepto_impuestos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.factura_concepto_impuestos_id_seq OWNED BY public.factura_concepto_impuestos.id;


--
-- TOC entry 253 (class 1259 OID 24954)
-- Name: factura_conceptos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.factura_conceptos (
    id integer NOT NULL,
    factura_id integer NOT NULL,
    clave_prod_serv character varying(10) NOT NULL,
    no_identificacion character varying(100),
    cantidad numeric(16,6) NOT NULL,
    clave_unidad character varying(10) NOT NULL,
    unidad character varying(50),
    descripcion text NOT NULL,
    precio_unitario numeric(16,6) NOT NULL,
    importe numeric(16,2) NOT NULL,
    descuento numeric(16,2) DEFAULT 0,
    objeto_impuesto character varying(2) DEFAULT '02'::character varying NOT NULL,
    numero_linea integer NOT NULL,
    creado_en timestamp without time zone DEFAULT now(),
    CONSTRAINT check_cantidad_positiva CHECK ((cantidad > (0)::numeric)),
    CONSTRAINT check_objeto_impuesto CHECK (((objeto_impuesto)::text = ANY ((ARRAY['01'::character varying, '02'::character varying, '03'::character varying, '04'::character varying])::text[]))),
    CONSTRAINT check_precio_positivo CHECK ((precio_unitario >= (0)::numeric))
);


ALTER TABLE public.factura_conceptos OWNER TO postgres;

--
-- TOC entry 5363 (class 0 OID 0)
-- Dependencies: 253
-- Name: TABLE factura_conceptos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.factura_conceptos IS 'Conceptos (productos/servicios) de cada factura';


--
-- TOC entry 5364 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN factura_conceptos.clave_prod_serv; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.factura_conceptos.clave_prod_serv IS 'Clave del catálogo de productos y servicios del SAT';


--
-- TOC entry 5365 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN factura_conceptos.clave_unidad; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.factura_conceptos.clave_unidad IS 'Clave de unidad de medida del SAT (H87=Pieza, E48=Servicio, etc)';


--
-- TOC entry 5366 (class 0 OID 0)
-- Dependencies: 253
-- Name: COLUMN factura_conceptos.objeto_impuesto; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.factura_conceptos.objeto_impuesto IS '01=No objeto, 02=Sí objeto, 03=Sí objeto pero no obligado, 04=Sí objeto no obligado devuelto';


--
-- TOC entry 252 (class 1259 OID 24953)
-- Name: factura_conceptos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.factura_conceptos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.factura_conceptos_id_seq OWNER TO postgres;

--
-- TOC entry 5367 (class 0 OID 0)
-- Dependencies: 252
-- Name: factura_conceptos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.factura_conceptos_id_seq OWNED BY public.factura_conceptos.id;


--
-- TOC entry 257 (class 1259 OID 25009)
-- Name: factura_pagos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.factura_pagos (
    id integer NOT NULL,
    factura_id integer NOT NULL,
    fecha_pago timestamp without time zone NOT NULL,
    forma_pago character varying(10) NOT NULL,
    moneda character varying(3) DEFAULT 'MXN'::character varying NOT NULL,
    tipo_cambio numeric(10,6),
    monto numeric(16,2) NOT NULL,
    num_operacion character varying(100),
    rfc_emisor_cta_ord character varying(13),
    nom_banco_ord character varying(100),
    cta_ordenante character varying(50),
    rfc_emisor_cta_ben character varying(13),
    cta_beneficiario character varying(50),
    creado_en timestamp without time zone DEFAULT now(),
    CONSTRAINT check_monto_positivo CHECK ((monto > (0)::numeric))
);


ALTER TABLE public.factura_pagos OWNER TO postgres;

--
-- TOC entry 5368 (class 0 OID 0)
-- Dependencies: 257
-- Name: TABLE factura_pagos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.factura_pagos IS 'Complemento de pagos para CFDI tipo P (Pago)';


--
-- TOC entry 256 (class 1259 OID 25008)
-- Name: factura_pagos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.factura_pagos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.factura_pagos_id_seq OWNER TO postgres;

--
-- TOC entry 5369 (class 0 OID 0)
-- Dependencies: 256
-- Name: factura_pagos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.factura_pagos_id_seq OWNED BY public.factura_pagos.id;


--
-- TOC entry 239 (class 1259 OID 24764)
-- Name: factura_ventas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.factura_ventas (
    factura_id integer NOT NULL,
    venta_id integer NOT NULL
);


ALTER TABLE public.factura_ventas OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 24755)
-- Name: facturas; Type: TABLE; Schema: public; Owner: postgres
--

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
    pdf_url character varying(500),
    nombre_emisor character varying(255),
    regimen_fiscal_emisor character varying(10),
    lugar_expedicion character varying(5),
    nombre_receptor character varying(255),
    regimen_fiscal_receptor character varying(10),
    domicilio_fiscal_receptor character varying(500),
    residencia_fiscal character varying(3),
    num_reg_id_trib character varying(40),
    tipo_comprobante character varying(1) DEFAULT 'I'::character varying,
    moneda character varying(3) DEFAULT 'MXN'::character varying,
    tipo_cambio numeric(10,6),
    exportacion character varying(3) DEFAULT '01'::character varying,
    subtotal numeric(16,2),
    descuento numeric(16,2) DEFAULT 0,
    iva_trasladado numeric(16,2) DEFAULT 0,
    iva_retenido numeric(16,2) DEFAULT 0,
    ieps_trasladado numeric(16,2) DEFAULT 0,
    isr_retenido numeric(16,2) DEFAULT 0,
    fecha_emision timestamp without time zone,
    fecha_timbrado timestamp without time zone,
    fecha_certificacion timestamp without time zone,
    certificado_sat character varying(50),
    sello_cfdi text,
    sello_sat text,
    cadena_original_sat text,
    no_certificado_emisor character varying(50),
    no_certificado_sat character varying(50),
    tipo_relacion character varying(2),
    uuid_relacionados text[],
    observaciones text,
    motivo_cancelacion character varying(2),
    fecha_cancelacion timestamp without time zone,
    CONSTRAINT check_estado CHECK (((estado)::text = ANY ((ARRAY['BORRADOR'::character varying, 'TIMBRADA'::character varying, 'CANCELADA'::character varying])::text[]))),
    CONSTRAINT check_moneda CHECK (((moneda)::text = ANY ((ARRAY['MXN'::character varying, 'USD'::character varying, 'EUR'::character varying, 'CAD'::character varying, 'GBP'::character varying, 'JPY'::character varying])::text[]))),
    CONSTRAINT check_tipo_comprobante CHECK (((tipo_comprobante)::text = ANY ((ARRAY['I'::character varying, 'E'::character varying, 'T'::character varying, 'P'::character varying, 'N'::character varying])::text[])))
);


ALTER TABLE public.facturas OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 24754)
-- Name: facturas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.facturas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.facturas_id_seq OWNER TO postgres;

--
-- TOC entry 5370 (class 0 OID 0)
-- Dependencies: 237
-- Name: facturas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.facturas_id_seq OWNED BY public.facturas.id;


--
-- TOC entry 241 (class 1259 OID 24782)
-- Name: folios_sat; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.folios_sat (
    id integer NOT NULL,
    serie character varying(10),
    folio_actual integer NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE public.folios_sat OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 24781)
-- Name: folios_sat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.folios_sat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.folios_sat_id_seq OWNER TO postgres;

--
-- TOC entry 5371 (class 0 OID 0)
-- Dependencies: 240
-- Name: folios_sat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.folios_sat_id_seq OWNED BY public.folios_sat.id;


--
-- TOC entry 230 (class 1259 OID 24664)
-- Name: inventario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario (
    id integer NOT NULL,
    variante_id integer NOT NULL,
    stock integer NOT NULL,
    actualizado_en timestamp without time zone DEFAULT now(),
    CONSTRAINT inventario_stock_check CHECK ((stock >= 0))
);


ALTER TABLE public.inventario OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 24663)
-- Name: inventario_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_id_seq OWNER TO postgres;

--
-- TOC entry 5372 (class 0 OID 0)
-- Dependencies: 229
-- Name: inventario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_id_seq OWNED BY public.inventario.id;


--
-- TOC entry 232 (class 1259 OID 24683)
-- Name: movimientos_inventario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimientos_inventario (
    id integer NOT NULL,
    variante_id integer NOT NULL,
    tipo character varying(20) NOT NULL,
    cantidad integer NOT NULL,
    referencia text,
    creado_en timestamp without time zone DEFAULT now(),
    CONSTRAINT movimientos_inventario_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT movimientos_inventario_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['ENTRADA'::character varying, 'SALIDA'::character varying, 'AJUSTE'::character varying])::text[])))
);


ALTER TABLE public.movimientos_inventario OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 24682)
-- Name: movimientos_inventario_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.movimientos_inventario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.movimientos_inventario_id_seq OWNER TO postgres;

--
-- TOC entry 5373 (class 0 OID 0)
-- Dependencies: 231
-- Name: movimientos_inventario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.movimientos_inventario_id_seq OWNED BY public.movimientos_inventario.id;


--
-- TOC entry 249 (class 1259 OID 24873)
-- Name: pagos_cuenta; Type: TABLE; Schema: public; Owner: postgres
--

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


ALTER TABLE public.pagos_cuenta OWNER TO postgres;

--
-- TOC entry 5374 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE pagos_cuenta; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.pagos_cuenta IS 'Pagos/abonos a cuentas por cobrar';


--
-- TOC entry 248 (class 1259 OID 24872)
-- Name: pagos_cuenta_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pagos_cuenta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pagos_cuenta_id_seq OWNER TO postgres;

--
-- TOC entry 5375 (class 0 OID 0)
-- Dependencies: 248
-- Name: pagos_cuenta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pagos_cuenta_id_seq OWNED BY public.pagos_cuenta.id;


--
-- TOC entry 226 (class 1259 OID 24626)
-- Name: productos; Type: TABLE; Schema: public; Owner: postgres
--

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


ALTER TABLE public.productos OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 24625)
-- Name: productos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.productos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.productos_id_seq OWNER TO postgres;

--
-- TOC entry 5376 (class 0 OID 0)
-- Dependencies: 225
-- Name: productos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.productos_id_seq OWNED BY public.productos.id;


--
-- TOC entry 224 (class 1259 OID 24612)
-- Name: puntos_venta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.puntos_venta (
    id integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descripcion text,
    activo boolean DEFAULT true
);


ALTER TABLE public.puntos_venta OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 24611)
-- Name: puntos_venta_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.puntos_venta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.puntos_venta_id_seq OWNER TO postgres;

--
-- TOC entry 5377 (class 0 OID 0)
-- Dependencies: 223
-- Name: puntos_venta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.puntos_venta_id_seq OWNED BY public.puntos_venta.id;


--
-- TOC entry 220 (class 1259 OID 24578)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    nombre character varying(50) NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 24577)
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_id_seq OWNER TO postgres;

--
-- TOC entry 5378 (class 0 OID 0)
-- Dependencies: 219
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- TOC entry 243 (class 1259 OID 24792)
-- Name: tickets; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tickets (
    id integer NOT NULL,
    venta_id integer NOT NULL,
    contenido text,
    creado_en timestamp without time zone DEFAULT now()
);


ALTER TABLE public.tickets OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 24791)
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tickets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tickets_id_seq OWNER TO postgres;

--
-- TOC entry 5379 (class 0 OID 0)
-- Dependencies: 242
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tickets_id_seq OWNED BY public.tickets.id;


--
-- TOC entry 222 (class 1259 OID 24589)
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    password_hash text NOT NULL,
    rol_id integer NOT NULL,
    activo boolean DEFAULT true,
    creado_en timestamp without time zone DEFAULT now()
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 24588)
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuarios_id_seq OWNER TO postgres;

--
-- TOC entry 5380 (class 0 OID 0)
-- Dependencies: 221
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- TOC entry 259 (class 1259 OID 25035)
-- Name: v_conceptos_con_impuestos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_conceptos_con_impuestos AS
SELECT
    NULL::integer AS id,
    NULL::integer AS factura_id,
    NULL::integer AS numero_linea,
    NULL::character varying(10) AS clave_prod_serv,
    NULL::character varying(100) AS no_identificacion,
    NULL::numeric(16,6) AS cantidad,
    NULL::character varying(10) AS clave_unidad,
    NULL::character varying(50) AS unidad,
    NULL::text AS descripcion,
    NULL::numeric(16,6) AS precio_unitario,
    NULL::numeric(16,2) AS importe,
    NULL::numeric(16,2) AS descuento,
    NULL::character varying(2) AS objeto_impuesto,
    NULL::numeric AS impuestos_trasladados,
    NULL::numeric AS impuestos_retenidos,
    NULL::numeric AS total_concepto;


ALTER VIEW public.v_conceptos_con_impuestos OWNER TO postgres;

--
-- TOC entry 5381 (class 0 OID 0)
-- Dependencies: 259
-- Name: VIEW v_conceptos_con_impuestos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.v_conceptos_con_impuestos IS 'Vista de conceptos con cálculo de impuestos';


--
-- TOC entry 258 (class 1259 OID 25030)
-- Name: v_facturas_completas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_facturas_completas AS
SELECT
    NULL::integer AS id,
    NULL::character varying(10) AS serie,
    NULL::integer AS folio,
    NULL::character varying(50) AS uuid_sat,
    NULL::character varying(1) AS tipo_comprobante,
    NULL::timestamp without time zone AS fecha_emision,
    NULL::timestamp without time zone AS fecha_timbrado,
    NULL::character varying(13) AS rfc_emisor,
    NULL::character varying(255) AS nombre_emisor,
    NULL::character varying(10) AS regimen_fiscal_emisor,
    NULL::character varying(5) AS lugar_expedicion,
    NULL::character varying(13) AS rfc_receptor,
    NULL::character varying(255) AS nombre_receptor,
    NULL::character varying(10) AS regimen_fiscal_receptor,
    NULL::character varying(10) AS uso_cfdi,
    NULL::character varying(3) AS moneda,
    NULL::numeric(10,6) AS tipo_cambio,
    NULL::numeric(16,2) AS subtotal,
    NULL::numeric(16,2) AS descuento,
    NULL::numeric(16,2) AS iva_trasladado,
    NULL::numeric(16,2) AS iva_retenido,
    NULL::numeric(16,2) AS ieps_trasladado,
    NULL::numeric(16,2) AS isr_retenido,
    NULL::numeric(12,2) AS total,
    NULL::character varying(20) AS estado,
    NULL::character varying(10) AS forma_pago,
    NULL::character varying(10) AS metodo_pago,
    NULL::character varying(500) AS xml_url,
    NULL::character varying(500) AS pdf_url,
    NULL::bigint AS total_conceptos,
    NULL::bigint AS total_ventas,
    NULL::timestamp without time zone AS creada_en;


ALTER VIEW public.v_facturas_completas OWNER TO postgres;

--
-- TOC entry 5382 (class 0 OID 0)
-- Dependencies: 258
-- Name: VIEW v_facturas_completas; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.v_facturas_completas IS 'Vista completa de facturas con totales y conteos';


--
-- TOC entry 228 (class 1259 OID 24639)
-- Name: variantes_producto; Type: TABLE; Schema: public; Owner: postgres
--

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


ALTER TABLE public.variantes_producto OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 24638)
-- Name: variantes_producto_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.variantes_producto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.variantes_producto_id_seq OWNER TO postgres;

--
-- TOC entry 5383 (class 0 OID 0)
-- Dependencies: 227
-- Name: variantes_producto_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.variantes_producto_id_seq OWNED BY public.variantes_producto.id;


--
-- TOC entry 236 (class 1259 OID 24729)
-- Name: venta_detalle; Type: TABLE; Schema: public; Owner: postgres
--

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


ALTER TABLE public.venta_detalle OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 24728)
-- Name: venta_detalle_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.venta_detalle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.venta_detalle_id_seq OWNER TO postgres;

--
-- TOC entry 5384 (class 0 OID 0)
-- Dependencies: 235
-- Name: venta_detalle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.venta_detalle_id_seq OWNED BY public.venta_detalle.id;


--
-- TOC entry 234 (class 1259 OID 24704)
-- Name: ventas; Type: TABLE; Schema: public; Owner: postgres
--

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
    CONSTRAINT ventas_metodo_pago_check CHECK (((metodo_pago)::text = ANY ((ARRAY['EFECTIVO'::character varying, 'TARJETA'::character varying])::text[]))),
    CONSTRAINT ventas_subtotal_check CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT ventas_tipo_venta_check CHECK (((tipo_venta)::text = ANY ((ARRAY['CONTADO'::character varying, 'CREDITO'::character varying])::text[]))),
    CONSTRAINT ventas_total_check CHECK ((total >= (0)::numeric))
);


ALTER TABLE public.ventas OWNER TO postgres;

--
-- TOC entry 5385 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN ventas.subtotal; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.ventas.subtotal IS 'Suma de todos los items antes de descuentos e impuestos';


--
-- TOC entry 5386 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN ventas.descuento; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.ventas.descuento IS 'Descuento aplicado a la venta completa';


--
-- TOC entry 5387 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN ventas.impuesto; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.ventas.impuesto IS 'Impuestos calculados (IVA u otros)';


--
-- TOC entry 5388 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN ventas.estado; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.ventas.estado IS 'Estado de la venta: ABIERTA (en proceso), CERRADA (completada), CANCELADA';


--
-- TOC entry 5389 (class 0 OID 0)
-- Dependencies: 234
-- Name: COLUMN ventas.tipo_venta; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.ventas.tipo_venta IS 'CONTADO (pago inmediato) o CREDITO (pago diferido)';


--
-- TOC entry 233 (class 1259 OID 24703)
-- Name: ventas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ventas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ventas_id_seq OWNER TO postgres;

--
-- TOC entry 5390 (class 0 OID 0)
-- Dependencies: 233
-- Name: ventas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ventas_id_seq OWNED BY public.ventas.id;


--
-- TOC entry 5005 (class 2604 OID 24835)
-- Name: clientes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes ALTER COLUMN id SET DEFAULT nextval('public.clientes_id_seq'::regclass);


--
-- TOC entry 5015 (class 2604 OID 24924)
-- Name: configuracion_fiscal id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion_fiscal ALTER COLUMN id SET DEFAULT nextval('public.configuracion_fiscal_id_seq'::regclass);


--
-- TOC entry 5009 (class 2604 OID 24849)
-- Name: cuentas_por_cobrar id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_por_cobrar ALTER COLUMN id SET DEFAULT nextval('public.cuentas_por_cobrar_id_seq'::regclass);


--
-- TOC entry 5024 (class 2604 OID 24988)
-- Name: factura_concepto_impuestos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_concepto_impuestos ALTER COLUMN id SET DEFAULT nextval('public.factura_concepto_impuestos_id_seq'::regclass);


--
-- TOC entry 5020 (class 2604 OID 24957)
-- Name: factura_conceptos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_conceptos ALTER COLUMN id SET DEFAULT nextval('public.factura_conceptos_id_seq'::regclass);


--
-- TOC entry 5025 (class 2604 OID 25012)
-- Name: factura_pagos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_pagos ALTER COLUMN id SET DEFAULT nextval('public.factura_pagos_id_seq'::regclass);


--
-- TOC entry 4990 (class 2604 OID 24758)
-- Name: facturas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facturas ALTER COLUMN id SET DEFAULT nextval('public.facturas_id_seq'::regclass);


--
-- TOC entry 5001 (class 2604 OID 24785)
-- Name: folios_sat id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folios_sat ALTER COLUMN id SET DEFAULT nextval('public.folios_sat_id_seq'::regclass);


--
-- TOC entry 4978 (class 2604 OID 24667)
-- Name: inventario id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario ALTER COLUMN id SET DEFAULT nextval('public.inventario_id_seq'::regclass);


--
-- TOC entry 4980 (class 2604 OID 24686)
-- Name: movimientos_inventario id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario ALTER COLUMN id SET DEFAULT nextval('public.movimientos_inventario_id_seq'::regclass);


--
-- TOC entry 5013 (class 2604 OID 24876)
-- Name: pagos_cuenta id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos_cuenta ALTER COLUMN id SET DEFAULT nextval('public.pagos_cuenta_id_seq'::regclass);


--
-- TOC entry 4972 (class 2604 OID 24629)
-- Name: productos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos ALTER COLUMN id SET DEFAULT nextval('public.productos_id_seq'::regclass);


--
-- TOC entry 4970 (class 2604 OID 24615)
-- Name: puntos_venta id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.puntos_venta ALTER COLUMN id SET DEFAULT nextval('public.puntos_venta_id_seq'::regclass);


--
-- TOC entry 4966 (class 2604 OID 24581)
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- TOC entry 5003 (class 2604 OID 24795)
-- Name: tickets id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets ALTER COLUMN id SET DEFAULT nextval('public.tickets_id_seq'::regclass);


--
-- TOC entry 4967 (class 2604 OID 24592)
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- TOC entry 4976 (class 2604 OID 24642)
-- Name: variantes_producto id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variantes_producto ALTER COLUMN id SET DEFAULT nextval('public.variantes_producto_id_seq'::regclass);


--
-- TOC entry 4989 (class 2604 OID 24732)
-- Name: venta_detalle id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_detalle ALTER COLUMN id SET DEFAULT nextval('public.venta_detalle_id_seq'::regclass);


--
-- TOC entry 4982 (class 2604 OID 24707)
-- Name: ventas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas ALTER COLUMN id SET DEFAULT nextval('public.ventas_id_seq'::regclass);


--
-- TOC entry 5330 (class 0 OID 24832)
-- Dependencies: 245
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clientes (id, nombre, rfc, telefono, email, direccion, limite_credito, activo, creado_en) FROM stdin;
1	PÚBLICO EN GENERAL	XAXX010101000	\N	\N	\N	0.00	t	2026-01-21 19:08:48.204935
\.


--
-- TOC entry 5336 (class 0 OID 24921)
-- Dependencies: 251
-- Data for Name: configuracion_fiscal; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.configuracion_fiscal (id, rfc_emisor, nombre_emisor, razon_social, regimen_fiscal, calle, numero_exterior, numero_interior, colonia, localidad, municipio, estado, pais, codigo_postal, certificado_cer, certificado_key, certificado_password, no_certificado, vigencia_desde, vigencia_hasta, activo, creado_en, actualizado_en) FROM stdin;
1	XAXX010101000	EMPRESA EJEMPLO SA DE CV	EMPRESA EJEMPLO SA DE CV	601	CALLE EJEMPLO	123	\N	COLONIA EJEMPLO	\N	CIUDAD DE MÉXICO	CIUDAD DE MÉXICO	México	03410	\N	\N	\N	\N	\N	\N	t	2026-01-28 10:07:10.945872	2026-01-28 10:07:10.945872
\.


--
-- TOC entry 5332 (class 0 OID 24846)
-- Dependencies: 247
-- Data for Name: cuentas_por_cobrar; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cuentas_por_cobrar (id, venta_id, cliente_id, monto_total, monto_pagado, saldo_pendiente, fecha_vencimiento, estado, creada_en) FROM stdin;
\.


--
-- TOC entry 5340 (class 0 OID 24985)
-- Dependencies: 255
-- Data for Name: factura_concepto_impuestos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.factura_concepto_impuestos (id, concepto_id, tipo_movimiento, base, impuesto, tipo_factor, tasa_o_cuota, importe) FROM stdin;
\.


--
-- TOC entry 5338 (class 0 OID 24954)
-- Dependencies: 253
-- Data for Name: factura_conceptos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.factura_conceptos (id, factura_id, clave_prod_serv, no_identificacion, cantidad, clave_unidad, unidad, descripcion, precio_unitario, importe, descuento, objeto_impuesto, numero_linea, creado_en) FROM stdin;
\.


--
-- TOC entry 5342 (class 0 OID 25009)
-- Dependencies: 257
-- Data for Name: factura_pagos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.factura_pagos (id, factura_id, fecha_pago, forma_pago, moneda, tipo_cambio, monto, num_operacion, rfc_emisor_cta_ord, nom_banco_ord, cta_ordenante, rfc_emisor_cta_ben, cta_beneficiario, creado_en) FROM stdin;
\.


--
-- TOC entry 5324 (class 0 OID 24764)
-- Dependencies: 239
-- Data for Name: factura_ventas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.factura_ventas (factura_id, venta_id) FROM stdin;
\.


--
-- TOC entry 5323 (class 0 OID 24755)
-- Dependencies: 238
-- Data for Name: facturas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.facturas (id, uuid_sat, fecha, total, rfc_emisor, rfc_receptor, creada_en, serie, folio, uso_cfdi, forma_pago, metodo_pago, estado, xml_content, xml_url, pdf_url, nombre_emisor, regimen_fiscal_emisor, lugar_expedicion, nombre_receptor, regimen_fiscal_receptor, domicilio_fiscal_receptor, residencia_fiscal, num_reg_id_trib, tipo_comprobante, moneda, tipo_cambio, exportacion, subtotal, descuento, iva_trasladado, iva_retenido, ieps_trasladado, isr_retenido, fecha_emision, fecha_timbrado, fecha_certificacion, certificado_sat, sello_cfdi, sello_sat, cadena_original_sat, no_certificado_emisor, no_certificado_sat, tipo_relacion, uuid_relacionados, observaciones, motivo_cancelacion, fecha_cancelacion) FROM stdin;
\.


--
-- TOC entry 5326 (class 0 OID 24782)
-- Dependencies: 241
-- Data for Name: folios_sat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.folios_sat (id, serie, folio_actual, activo) FROM stdin;
\.


--
-- TOC entry 5315 (class 0 OID 24664)
-- Dependencies: 230
-- Data for Name: inventario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventario (id, variante_id, stock, actualizado_en) FROM stdin;
1	1	5	2026-01-13 23:26:55.694197
\.


--
-- TOC entry 5317 (class 0 OID 24683)
-- Dependencies: 232
-- Data for Name: movimientos_inventario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movimientos_inventario (id, variante_id, tipo, cantidad, referencia, creado_en) FROM stdin;
1	1	SALIDA	5	Venta ID 3	2026-01-13 23:26:21.088087
2	1	SALIDA	12	Venta ID 3	2026-01-13 23:26:55.694197
\.


--
-- TOC entry 5334 (class 0 OID 24873)
-- Dependencies: 249
-- Data for Name: pagos_cuenta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pagos_cuenta (id, cuenta_id, monto, metodo_pago, referencia, notas, usuario_id, creado_en) FROM stdin;
\.


--
-- TOC entry 5311 (class 0 OID 24626)
-- Dependencies: 226
-- Data for Name: productos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.productos (id, nombre, descripcion, activo, creado_en, categoria, marca, actualizado_en) FROM stdin;
1	Playera Básica	\N	t	2026-01-13 23:24:18.822453	\N	\N	\N
\.


--
-- TOC entry 5309 (class 0 OID 24612)
-- Dependencies: 224
-- Data for Name: puntos_venta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.puntos_venta (id, codigo, descripcion, activo) FROM stdin;
1	POS01	Caja principal almacén	t
\.


--
-- TOC entry 5305 (class 0 OID 24578)
-- Dependencies: 220
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, nombre) FROM stdin;
1	ADMIN
2	CAJERO
3	ALMACEN
\.


--
-- TOC entry 5328 (class 0 OID 24792)
-- Dependencies: 243
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tickets (id, venta_id, contenido, creado_en) FROM stdin;
\.


--
-- TOC entry 5307 (class 0 OID 24589)
-- Dependencies: 222
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id, nombre, email, password_hash, rol_id, activo, creado_en) FROM stdin;
1	Admin	admin@local.com	$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqVhC6U7QK	1	t	2026-01-13 23:14:44.883577
2	Cajero	cajero@local.com	$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36BvQxW5wVaD8IfaKZ1.dCS	2	t	2026-01-21 09:32:12.71168
\.


--
-- TOC entry 5313 (class 0 OID 24639)
-- Dependencies: 228
-- Data for Name: variantes_producto; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.variantes_producto (id, producto_id, sku, talla, color, precio_menudeo, precio_mayoreo, codigo_barras, activo) FROM stdin;
1	1	PLY-BAS-M-NEG	M	Negro	600.00	500.00	7501234567890	t
\.


--
-- TOC entry 5321 (class 0 OID 24729)
-- Dependencies: 236
-- Data for Name: venta_detalle; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.venta_detalle (id, venta_id, variante_id, cantidad, precio_unitario, subtotal) FROM stdin;
4	3	1	5	600.00	3000.00
5	3	1	12	500.00	6000.00
\.


--
-- TOC entry 5319 (class 0 OID 24704)
-- Dependencies: 234
-- Data for Name: ventas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ventas (id, punto_venta_id, usuario_id, total, metodo_pago, creada_en, subtotal, descuento, impuesto, estado, completed_at, cliente_id, tipo_venta) FROM stdin;
2	1	1	0.00	EFECTIVO	2026-01-13 23:14:57.862652	0.00	0.00	0.00	ABIERTA	\N	\N	CONTADO
3	1	1	0.00	EFECTIVO	2026-01-13 23:26:08.738877	0.00	0.00	0.00	ABIERTA	\N	\N	CONTADO
\.


--
-- TOC entry 5391 (class 0 OID 0)
-- Dependencies: 244
-- Name: clientes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clientes_id_seq', 1, true);


--
-- TOC entry 5392 (class 0 OID 0)
-- Dependencies: 250
-- Name: configuracion_fiscal_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.configuracion_fiscal_id_seq', 1, true);


--
-- TOC entry 5393 (class 0 OID 0)
-- Dependencies: 246
-- Name: cuentas_por_cobrar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cuentas_por_cobrar_id_seq', 1, false);


--
-- TOC entry 5394 (class 0 OID 0)
-- Dependencies: 254
-- Name: factura_concepto_impuestos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.factura_concepto_impuestos_id_seq', 1, false);


--
-- TOC entry 5395 (class 0 OID 0)
-- Dependencies: 252
-- Name: factura_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.factura_conceptos_id_seq', 1, false);


--
-- TOC entry 5396 (class 0 OID 0)
-- Dependencies: 256
-- Name: factura_pagos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.factura_pagos_id_seq', 1, false);


--
-- TOC entry 5397 (class 0 OID 0)
-- Dependencies: 237
-- Name: facturas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.facturas_id_seq', 1, false);


--
-- TOC entry 5398 (class 0 OID 0)
-- Dependencies: 240
-- Name: folios_sat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.folios_sat_id_seq', 1, false);


--
-- TOC entry 5399 (class 0 OID 0)
-- Dependencies: 229
-- Name: inventario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inventario_id_seq', 1, true);


--
-- TOC entry 5400 (class 0 OID 0)
-- Dependencies: 231
-- Name: movimientos_inventario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.movimientos_inventario_id_seq', 3, true);


--
-- TOC entry 5401 (class 0 OID 0)
-- Dependencies: 248
-- Name: pagos_cuenta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pagos_cuenta_id_seq', 1, false);


--
-- TOC entry 5402 (class 0 OID 0)
-- Dependencies: 225
-- Name: productos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.productos_id_seq', 1, true);


--
-- TOC entry 5403 (class 0 OID 0)
-- Dependencies: 223
-- Name: puntos_venta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.puntos_venta_id_seq', 1, true);


--
-- TOC entry 5404 (class 0 OID 0)
-- Dependencies: 219
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_seq', 3, true);


--
-- TOC entry 5405 (class 0 OID 0)
-- Dependencies: 242
-- Name: tickets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tickets_id_seq', 1, false);


--
-- TOC entry 5406 (class 0 OID 0)
-- Dependencies: 221
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 2, true);


--
-- TOC entry 5407 (class 0 OID 0)
-- Dependencies: 227
-- Name: variantes_producto_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.variantes_producto_id_seq', 1, true);


--
-- TOC entry 5408 (class 0 OID 0)
-- Dependencies: 235
-- Name: venta_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.venta_detalle_id_seq', 7, true);


--
-- TOC entry 5409 (class 0 OID 0)
-- Dependencies: 233
-- Name: ventas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ventas_id_seq', 3, true);


--
-- TOC entry 5108 (class 2606 OID 24844)
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id);


--
-- TOC entry 5118 (class 2606 OID 24938)
-- Name: configuracion_fiscal configuracion_fiscal_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion_fiscal
    ADD CONSTRAINT configuracion_fiscal_pkey PRIMARY KEY (id);


--
-- TOC entry 5120 (class 2606 OID 24940)
-- Name: configuracion_fiscal configuracion_fiscal_rfc_emisor_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracion_fiscal
    ADD CONSTRAINT configuracion_fiscal_rfc_emisor_key UNIQUE (rfc_emisor);


--
-- TOC entry 5110 (class 2606 OID 24861)
-- Name: cuentas_por_cobrar cuentas_por_cobrar_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_por_cobrar
    ADD CONSTRAINT cuentas_por_cobrar_pkey PRIMARY KEY (id);


--
-- TOC entry 5125 (class 2606 OID 24998)
-- Name: factura_concepto_impuestos factura_concepto_impuestos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_concepto_impuestos
    ADD CONSTRAINT factura_concepto_impuestos_pkey PRIMARY KEY (id);


--
-- TOC entry 5122 (class 2606 OID 24974)
-- Name: factura_conceptos factura_conceptos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_conceptos
    ADD CONSTRAINT factura_conceptos_pkey PRIMARY KEY (id);


--
-- TOC entry 5128 (class 2606 OID 25022)
-- Name: factura_pagos factura_pagos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_pagos
    ADD CONSTRAINT factura_pagos_pkey PRIMARY KEY (id);


--
-- TOC entry 5102 (class 2606 OID 24770)
-- Name: factura_ventas factura_ventas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_ventas
    ADD CONSTRAINT factura_ventas_pkey PRIMARY KEY (factura_id, venta_id);


--
-- TOC entry 5093 (class 2606 OID 24763)
-- Name: facturas facturas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facturas
    ADD CONSTRAINT facturas_pkey PRIMARY KEY (id);


--
-- TOC entry 5104 (class 2606 OID 24790)
-- Name: folios_sat folios_sat_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.folios_sat
    ADD CONSTRAINT folios_sat_pkey PRIMARY KEY (id);


--
-- TOC entry 5079 (class 2606 OID 24674)
-- Name: inventario inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_pkey PRIMARY KEY (id);


--
-- TOC entry 5081 (class 2606 OID 24676)
-- Name: inventario inventario_variante_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_variante_id_key UNIQUE (variante_id);


--
-- TOC entry 5083 (class 2606 OID 24697)
-- Name: movimientos_inventario movimientos_inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_pkey PRIMARY KEY (id);


--
-- TOC entry 5116 (class 2606 OID 24887)
-- Name: pagos_cuenta pagos_cuenta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos_cuenta
    ADD CONSTRAINT pagos_cuenta_pkey PRIMARY KEY (id);


--
-- TOC entry 5071 (class 2606 OID 24637)
-- Name: productos productos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_pkey PRIMARY KEY (id);


--
-- TOC entry 5067 (class 2606 OID 24624)
-- Name: puntos_venta puntos_venta_codigo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.puntos_venta
    ADD CONSTRAINT puntos_venta_codigo_key UNIQUE (codigo);


--
-- TOC entry 5069 (class 2606 OID 24622)
-- Name: puntos_venta puntos_venta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.puntos_venta
    ADD CONSTRAINT puntos_venta_pkey PRIMARY KEY (id);


--
-- TOC entry 5059 (class 2606 OID 24587)
-- Name: roles roles_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_nombre_key UNIQUE (nombre);


--
-- TOC entry 5061 (class 2606 OID 24585)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 5106 (class 2606 OID 24802)
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- TOC entry 5063 (class 2606 OID 24605)
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- TOC entry 5065 (class 2606 OID 24603)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- TOC entry 5073 (class 2606 OID 24657)
-- Name: variantes_producto variantes_producto_codigo_barras_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variantes_producto
    ADD CONSTRAINT variantes_producto_codigo_barras_key UNIQUE (codigo_barras);


--
-- TOC entry 5075 (class 2606 OID 24653)
-- Name: variantes_producto variantes_producto_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variantes_producto
    ADD CONSTRAINT variantes_producto_pkey PRIMARY KEY (id);


--
-- TOC entry 5077 (class 2606 OID 24655)
-- Name: variantes_producto variantes_producto_sku_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variantes_producto
    ADD CONSTRAINT variantes_producto_sku_key UNIQUE (sku);


--
-- TOC entry 5091 (class 2606 OID 24743)
-- Name: venta_detalle venta_detalle_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT venta_detalle_pkey PRIMARY KEY (id);


--
-- TOC entry 5089 (class 2606 OID 24717)
-- Name: ventas ventas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_pkey PRIMARY KEY (id);


--
-- TOC entry 5126 (class 1259 OID 25004)
-- Name: idx_concepto_impuestos_concepto; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_concepto_impuestos_concepto ON public.factura_concepto_impuestos USING btree (concepto_id);


--
-- TOC entry 5111 (class 1259 OID 24907)
-- Name: idx_cuentas_cliente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cuentas_cliente ON public.cuentas_por_cobrar USING btree (cliente_id);


--
-- TOC entry 5112 (class 1259 OID 24908)
-- Name: idx_cuentas_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cuentas_estado ON public.cuentas_por_cobrar USING btree (estado);


--
-- TOC entry 5113 (class 1259 OID 24909)
-- Name: idx_cuentas_vencimiento; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cuentas_vencimiento ON public.cuentas_por_cobrar USING btree (fecha_vencimiento);


--
-- TOC entry 5123 (class 1259 OID 24980)
-- Name: idx_factura_conceptos_factura; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_factura_conceptos_factura ON public.factura_conceptos USING btree (factura_id);


--
-- TOC entry 5129 (class 1259 OID 25028)
-- Name: idx_factura_pagos_factura; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_factura_pagos_factura ON public.factura_pagos USING btree (factura_id);


--
-- TOC entry 5094 (class 1259 OID 24918)
-- Name: idx_facturas_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_facturas_estado ON public.facturas USING btree (estado);


--
-- TOC entry 5095 (class 1259 OID 24919)
-- Name: idx_facturas_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_facturas_fecha ON public.facturas USING btree (fecha);


--
-- TOC entry 5096 (class 1259 OID 25044)
-- Name: idx_facturas_fecha_emision; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_facturas_fecha_emision ON public.facturas USING btree (fecha_emision);


--
-- TOC entry 5097 (class 1259 OID 25045)
-- Name: idx_facturas_rfc_receptor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_facturas_rfc_receptor ON public.facturas USING btree (rfc_receptor);


--
-- TOC entry 5098 (class 1259 OID 25046)
-- Name: idx_facturas_serie_folio; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_facturas_serie_folio ON public.facturas USING btree (serie, folio);


--
-- TOC entry 5099 (class 1259 OID 25043)
-- Name: idx_facturas_uuid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_facturas_uuid ON public.facturas USING btree (uuid_sat);


--
-- TOC entry 5100 (class 1259 OID 24917)
-- Name: idx_facturas_uuid_sat; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_facturas_uuid_sat ON public.facturas USING btree (uuid_sat);


--
-- TOC entry 5114 (class 1259 OID 24910)
-- Name: idx_pagos_cuenta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pagos_cuenta ON public.pagos_cuenta USING btree (cuenta_id);


--
-- TOC entry 5084 (class 1259 OID 24911)
-- Name: idx_ventas_cliente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ventas_cliente ON public.ventas USING btree (cliente_id);


--
-- TOC entry 5085 (class 1259 OID 24825)
-- Name: idx_ventas_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ventas_estado ON public.ventas USING btree (estado);


--
-- TOC entry 5086 (class 1259 OID 24808)
-- Name: idx_ventas_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ventas_fecha ON public.ventas USING btree (creada_en);


--
-- TOC entry 5087 (class 1259 OID 24826)
-- Name: idx_ventas_fecha_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ventas_fecha_estado ON public.ventas USING btree (creada_en, estado);


--
-- TOC entry 5303 (class 2618 OID 25038)
-- Name: v_conceptos_con_impuestos _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.v_conceptos_con_impuestos AS
 SELECT fc.id,
    fc.factura_id,
    fc.numero_linea,
    fc.clave_prod_serv,
    fc.no_identificacion,
    fc.cantidad,
    fc.clave_unidad,
    fc.unidad,
    fc.descripcion,
    fc.precio_unitario,
    fc.importe,
    fc.descuento,
    fc.objeto_impuesto,
    sum(
        CASE
            WHEN ((fci.tipo_movimiento)::text = 'TRASLADO'::text) THEN fci.importe
            ELSE (0)::numeric
        END) AS impuestos_trasladados,
    sum(
        CASE
            WHEN ((fci.tipo_movimiento)::text = 'RETENCION'::text) THEN fci.importe
            ELSE (0)::numeric
        END) AS impuestos_retenidos,
    (((fc.importe - fc.descuento) + sum(
        CASE
            WHEN ((fci.tipo_movimiento)::text = 'TRASLADO'::text) THEN fci.importe
            ELSE (0)::numeric
        END)) - sum(
        CASE
            WHEN ((fci.tipo_movimiento)::text = 'RETENCION'::text) THEN fci.importe
            ELSE (0)::numeric
        END)) AS total_concepto
   FROM (public.factura_conceptos fc
     LEFT JOIN public.factura_concepto_impuestos fci ON ((fc.id = fci.concepto_id)))
  GROUP BY fc.id;


--
-- TOC entry 5302 (class 2618 OID 25033)
-- Name: v_facturas_completas _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.v_facturas_completas AS
 SELECT f.id,
    f.serie,
    f.folio,
    f.uuid_sat,
    f.tipo_comprobante,
    f.fecha_emision,
    f.fecha_timbrado,
    f.rfc_emisor,
    f.nombre_emisor,
    f.regimen_fiscal_emisor,
    f.lugar_expedicion,
    f.rfc_receptor,
    f.nombre_receptor,
    f.regimen_fiscal_receptor,
    f.uso_cfdi,
    f.moneda,
    f.tipo_cambio,
    f.subtotal,
    f.descuento,
    f.iva_trasladado,
    f.iva_retenido,
    f.ieps_trasladado,
    f.isr_retenido,
    f.total,
    f.estado,
    f.forma_pago,
    f.metodo_pago,
    f.xml_url,
    f.pdf_url,
    count(fc.id) AS total_conceptos,
    count(DISTINCT fv.venta_id) AS total_ventas,
    f.creada_en
   FROM ((public.facturas f
     LEFT JOIN public.factura_conceptos fc ON ((f.id = fc.factura_id)))
     LEFT JOIN public.factura_ventas fv ON ((f.id = fv.factura_id)))
  GROUP BY f.id;


--
-- TOC entry 5153 (class 2620 OID 24906)
-- Name: pagos_cuenta trg_actualizar_cuenta_pago; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_actualizar_cuenta_pago AFTER INSERT ON public.pagos_cuenta FOR EACH ROW EXECUTE FUNCTION public.fn_actualizar_cuenta_pago();


--
-- TOC entry 5149 (class 2620 OID 24814)
-- Name: venta_detalle trg_descuento_inventario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_descuento_inventario AFTER INSERT ON public.venta_detalle FOR EACH ROW EXECUTE FUNCTION public.fn_descuento_inventario();


--
-- TOC entry 5154 (class 2620 OID 25042)
-- Name: factura_conceptos trg_factura_conceptos_totales; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_factura_conceptos_totales AFTER INSERT OR DELETE OR UPDATE ON public.factura_conceptos FOR EACH ROW EXECUTE FUNCTION public.trg_recalcular_totales_factura();


--
-- TOC entry 5150 (class 2620 OID 24828)
-- Name: venta_detalle trg_precio_automatico_acumulado; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_precio_automatico_acumulado BEFORE INSERT ON public.venta_detalle FOR EACH ROW EXECUTE FUNCTION public.fn_precio_automatico_acumulado();


--
-- TOC entry 5151 (class 2620 OID 24830)
-- Name: venta_detalle trg_recalcular_totales; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_recalcular_totales AFTER INSERT OR DELETE OR UPDATE ON public.venta_detalle FOR EACH ROW EXECUTE FUNCTION public.fn_recalcular_totales_venta();


--
-- TOC entry 5152 (class 2620 OID 24816)
-- Name: venta_detalle trg_validar_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validar_stock BEFORE INSERT ON public.venta_detalle FOR EACH ROW EXECUTE FUNCTION public.fn_validar_stock();


--
-- TOC entry 5142 (class 2606 OID 24867)
-- Name: cuentas_por_cobrar cuentas_por_cobrar_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_por_cobrar
    ADD CONSTRAINT cuentas_por_cobrar_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- TOC entry 5143 (class 2606 OID 24862)
-- Name: cuentas_por_cobrar cuentas_por_cobrar_venta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cuentas_por_cobrar
    ADD CONSTRAINT cuentas_por_cobrar_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES public.ventas(id);


--
-- TOC entry 5147 (class 2606 OID 24999)
-- Name: factura_concepto_impuestos factura_concepto_impuestos_concepto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_concepto_impuestos
    ADD CONSTRAINT factura_concepto_impuestos_concepto_id_fkey FOREIGN KEY (concepto_id) REFERENCES public.factura_conceptos(id) ON DELETE CASCADE;


--
-- TOC entry 5146 (class 2606 OID 24975)
-- Name: factura_conceptos factura_conceptos_factura_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_conceptos
    ADD CONSTRAINT factura_conceptos_factura_id_fkey FOREIGN KEY (factura_id) REFERENCES public.facturas(id) ON DELETE CASCADE;


--
-- TOC entry 5148 (class 2606 OID 25023)
-- Name: factura_pagos factura_pagos_factura_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_pagos
    ADD CONSTRAINT factura_pagos_factura_id_fkey FOREIGN KEY (factura_id) REFERENCES public.facturas(id) ON DELETE CASCADE;


--
-- TOC entry 5139 (class 2606 OID 24771)
-- Name: factura_ventas factura_ventas_factura_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_ventas
    ADD CONSTRAINT factura_ventas_factura_id_fkey FOREIGN KEY (factura_id) REFERENCES public.facturas(id) ON DELETE CASCADE;


--
-- TOC entry 5140 (class 2606 OID 24776)
-- Name: factura_ventas factura_ventas_venta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura_ventas
    ADD CONSTRAINT factura_ventas_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES public.ventas(id) ON DELETE CASCADE;


--
-- TOC entry 5132 (class 2606 OID 24677)
-- Name: inventario inventario_variante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT inventario_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.variantes_producto(id);


--
-- TOC entry 5133 (class 2606 OID 24698)
-- Name: movimientos_inventario movimientos_inventario_variante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.variantes_producto(id);


--
-- TOC entry 5144 (class 2606 OID 24888)
-- Name: pagos_cuenta pagos_cuenta_cuenta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos_cuenta
    ADD CONSTRAINT pagos_cuenta_cuenta_id_fkey FOREIGN KEY (cuenta_id) REFERENCES public.cuentas_por_cobrar(id);


--
-- TOC entry 5145 (class 2606 OID 24893)
-- Name: pagos_cuenta pagos_cuenta_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagos_cuenta
    ADD CONSTRAINT pagos_cuenta_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- TOC entry 5141 (class 2606 OID 24803)
-- Name: tickets tickets_venta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES public.ventas(id);


--
-- TOC entry 5130 (class 2606 OID 24606)
-- Name: usuarios usuarios_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id);


--
-- TOC entry 5131 (class 2606 OID 24658)
-- Name: variantes_producto variantes_producto_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.variantes_producto
    ADD CONSTRAINT variantes_producto_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.productos(id) ON DELETE CASCADE;


--
-- TOC entry 5137 (class 2606 OID 24749)
-- Name: venta_detalle venta_detalle_variante_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT venta_detalle_variante_id_fkey FOREIGN KEY (variante_id) REFERENCES public.variantes_producto(id);


--
-- TOC entry 5138 (class 2606 OID 24744)
-- Name: venta_detalle venta_detalle_venta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venta_detalle
    ADD CONSTRAINT venta_detalle_venta_id_fkey FOREIGN KEY (venta_id) REFERENCES public.ventas(id) ON DELETE CASCADE;


--
-- TOC entry 5134 (class 2606 OID 24898)
-- Name: ventas ventas_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- TOC entry 5135 (class 2606 OID 24718)
-- Name: ventas ventas_punto_venta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_punto_venta_id_fkey FOREIGN KEY (punto_venta_id) REFERENCES public.puntos_venta(id);


--
-- TOC entry 5136 (class 2606 OID 24723)
-- Name: ventas ventas_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ventas
    ADD CONSTRAINT ventas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


-- Completed on 2026-02-09 09:46:03

--
-- PostgreSQL database dump complete
--

\unrestrict hMdBS6ZSRx7xYFqVt8KhkRheBTAGSlrNpmVTJ89ytRbVIMXJSB1m5gcaLQN6bcX

