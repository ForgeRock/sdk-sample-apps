import { writeFile } from 'fs';
import dotenv from 'dotenv';
dotenv.config();

// Assume development
let targetPath =
  process.env.NODE_ENV === 'production'
    ? 'src/environments/environment.prod.ts'
    : 'src/environments/environment.ts';

const envConfigFile = `export const environment = {
  API_URL: '${process.env.API_URL}',
  DEBUGGER_OFF: '${process.env.DEBUGGER_OFF}',
  DEVELOPMENT: '${process.env.DEVELOPMENT}',
  PORT: '${process.env.PORT}',
  CLIENT_ID: '${process.env.CLIENT_ID}',
  REDIRECT_URI: '${process.env.REDIRECT_URI}',
  SCOPE: '${process.env.SCOPE}',
  BASE_URL: '${process.env.BASE_URL}',
  production: '${process.env.NODE_ENV || 'development'}'
};`;

console.log(`The file ${targetPath} will be written with the following content: \n`);
console.log(envConfigFile);
writeFile(targetPath, envConfigFile, function (err) {
  if (err) {
    throw console.error(err);
  } else {
    console.log(`Angular environment file generated correctly at ${targetPath} \n`);
  }
});
