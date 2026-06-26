import countries from "i18n-iso-countries";
import english from "i18n-iso-countries/langs/en.json";

countries.registerLocale(english);

export const countryCodes = Object.entries(countries.getNames("en", { select: "official" }))
  .map(([alpha2, country]) => ({
    country,
    alpha2,
    alpha3: countries.alpha2ToAlpha3(alpha2) || "",
  }))
  .sort((left, right) => left.country.localeCompare(right.country));
