# Dashboard benchmark

Este benchmark mide el tiempo del dashboard completo para una revisión sistemática sintética con muchos documentos, decisiones y resoluciones.

No está en `spec/` porque es una prueba de rendimiento manual: depende de la máquina, del motor de base de datos, de caches, y puede tardar demasiado para CI.

## Script

```bash
bundle exec ruby benchmarks/dashboard_10k.rb
```

También puede ejecutarse directamente:

```bash
ruby benchmarks/dashboard_10k.rb
```

Por defecto crea una base SQLite temporal en `tmp/dashboard_10k.sqlite` con:

- 10.000 canonical documents.
- 10.000 records asociados a una búsqueda válida.
- 2 usuarios asignados por documento.
- Decisiones aleatorias para `screening_title_abstract` y `review_full_text`.
- Resoluciones reproducibles con semilla fija.
- Medición HTTP vía `Rack::Test` contra `/review/:id/dashboard`.

El script hace warmup y luego imprime `avg`, `min`, `median`, `p95` y `max`.

El script carga `bundler/setup` al inicio para evitar conflictos con default gems de Ruby, por ejemplo `date`, cuando se ejecuta con `ruby` directo.

## Opciones

Las opciones se configuran con variables de entorno:

```bash
RECORDS=10000 RUNS=20 WARMUP=5 SEED=1234 bundle exec ruby benchmarks/dashboard_10k.rb
```

Variables disponibles:

- `RECORDS`: número de documentos/records sintéticos. Default: `10000`.
- `RUNS`: número de mediciones. Default: `10`.
- `WARMUP`: requests previos que no se cuentan. Default: `3`.
- `SEED`: semilla para decisiones/resoluciones aleatorias. Default: `1234`.
- `BENCHMARK_DB`: ruta de la base SQLite. Default: `tmp/dashboard_10k.sqlite`.
- `RESET_DB`: si es `1`, recrea la base antes de medir. Default: `1`.
- `BATCH_SIZE`: tamaño de inserción masiva. Default: `1000`.

## Corrida rápida

Para validar que el benchmark funciona sin esperar la carga completa:

```bash
RECORDS=500 RUNS=3 WARMUP=1 bundle exec ruby benchmarks/dashboard_10k.rb
```

## Resultado local inicial

Corrida ejecutada en el entorno de desarrollo actual:

```bash
RECORDS=10000 RUNS=3 WARMUP=1 bundle exec ruby benchmarks/dashboard_10k.rb
```

Resultado:

```text
runs=3 avg=0.9813s min=0.9464s median=0.9783s p95=1.0192s max=1.0192s
```

## Interpretación

Use la misma máquina, la misma base de datos y la misma semilla para comparar cambios de código. El valor más útil para regresiones es `p95`, porque captura requests lentos sin depender de un único outlier extremo.

Para medir producción con más fidelidad, apunte `BENCHMARK_DB` a una base SQLite persistente o adapte el script a la `DATABASE_URL` real. No mezcle estos datos sintéticos con una base productiva.
