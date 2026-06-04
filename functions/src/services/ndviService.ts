import axios from "axios";
import { getSentinelToken } from "./sentinelAuth";

/**
 * Obtiene el NDVI promedio de un polígono en los últimos N días.
 * @param {number[][]} coordenadas - Array de [lng, lat] que forman el polígono del terreno
 * @param {number} diasAtras - Cuántos días hacia atrás buscar imágenes (default: 30)
 * @returns {Promise<{ndvi: number, fecha: string, muestreos: number}>}
 */
export async function obtenerNDVI(coordenadas: number[][], diasAtras = 30) {
  const token = await getSentinelToken();

  const fechaFin = new Date().toISOString().split("T")[0];
  const fechaInicio = new Date(Date.now() - diasAtras * 86400000)
    .toISOString()
    .split("T")[0];

  // Asegurar que el polígono esté cerrado (primer punto = último punto)
  const poligonoCerrado = [...coordenadas];
  if (
    JSON.stringify(coordenadas[0]) !==
    JSON.stringify(coordenadas[coordenadas.length - 1])
  ) {
    poligonoCerrado.push(coordenadas[0]);
  }

  // NDVI Evalscript
  const NDVI_EVALSCRIPT = `
    //VERSION=3
    function setup() {
      return {
        input: [{ bands: ["B04", "B08", "dataMask"] }],
        output: { bands: 1, sampleType: "FLOAT32" }
      };
    }
    function evaluatePixel(sample) {
      if (sample.dataMask === 0) return [NaN];
      let ndvi = (sample.B08 - sample.B04) / (sample.B08 + sample.B04);
      return [ndvi];
    }
  `;

  const statBody = {
    input: {
      bounds: {
        geometry: {
          type: "Polygon",
          coordinates: [poligonoCerrado],
        },
      },
      data: [
        {
          type: "sentinel-2-l2a",
          dataFilter: {
            timeRange: {
              from: `${fechaInicio}T00:00:00Z`,
              to: `${fechaFin}T23:59:59Z`,
            },
            maxCloudCoverage: 30, // Rechazar imágenes con >30% de nubes
          },
        },
      ],
    },
    aggregation: {
      timeRange: {
        from: `${fechaInicio}T00:00:00Z`,
        to: `${fechaFin}T23:59:59Z`,
      },
      aggregationInterval: { of: "P30D" }, // Agrupar en período de 30 días
      evalscript: NDVI_EVALSCRIPT,
      resx: 10, // Resolución 10m (Sentinel-2 nativo)
      resy: 10,
    },
    calculations: { default: {} },
  };

  const response = await axios.post(
    "https://sh.dataspace.copernicus.eu/api/v1/statistics",
    statBody,
    {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
    },
  );

  const datos = response.data;

  // Extraer NDVI promedio del intervalo más reciente
  const intervalos = datos.data?.[0]?.intervals || [];
  if (intervalos.length === 0) {
    throw new Error(
      "No hay imágenes Sentinel-2 disponibles para este período (posible cobertura de nubes)",
    );
  }

  const ultimo = intervalos[intervalos.length - 1];
  const ndviMean = ultimo.outputs?.default?.bands?.B0?.stats?.mean;

  return {
    ndvi: ndviMean,
    fecha: ultimo.to,
    muestreos: ultimo.outputs?.default?.bands?.B0?.stats?.sampleCount,
  };
}

module.exports = { obtenerNDVI };