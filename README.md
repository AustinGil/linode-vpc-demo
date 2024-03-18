# Linode VPC Demo Using Terraform

This demo app provisions two application servers and two databases. One app+db pair is publicly available and the other lives within its own private VPC network, only exposing the app server to public traffic. As a result even if the database credentials get exposed, only other computers within the VPC network can access the database.

The demo’s front end is built with [Qwik](https://qwik.dev/) and uses [Tailwind](https://tailwindcss.com/) for styling. The server side is powered by [Qwik City](https://qwik.dev/docs/qwikcity/) (Qwik’s official meta-framework) and runs on [Node.js](https://nodejs.org/) hosted on a [shared Linode VPS](https://www.linode.com/products/shared/). The apps also use [PM2](https://pm2.io/) for process management and [Caddy](https://caddyserver.com/) as a reverse proxy and SSL provisioner. The data is stored in a PostgreS[QL](https://www.postgresql.org/) database that also runs on a shared Lindode VPS. They interact with the database using [Drizzle](https://orm.drizzle.team/) Object-Relational Mapping (ORM). The entire infrastructure for each app is managed with [Terraform](https://www.terraform.io/) using the [Terraform Linode provider](https://registry.terraform.io/providers/linode/linode/latest/docs). See the `/terraform` folder for more details.

To provision your own app, copy the `/terraform/terraform.tfvars.example` file to `/terraform/terraform.tfvars` and set the appropriate configuration/environment variables.

The following is the default README for QwikCity.

# Qwik City App ⚡️

- [Qwik Docs](https://qwik.builder.io/)
- [Discord](https://qwik.builder.io/chat)
- [Qwik GitHub](https://github.com/BuilderIO/qwik)
- [@QwikDev](https://twitter.com/QwikDev)
- [Vite](https://vitejs.dev/)

---

## Project Structure

This project is using Qwik with [QwikCity](https://qwik.builder.io/qwikcity/overview/). QwikCity is just an extra set of tools on top of Qwik to make it easier to build a full site, including directory-based routing, layouts, and more.

Inside your project, you'll see the following directory structure:

```
├── public/
│   └── ...
└── src/
    ├── components/
    │   └── ...
    └── routes/
        └── ...
```

- `src/routes`: Provides the directory-based routing, which can include a hierarchy of `layout.tsx` layout files, and an `index.tsx` file as the page. Additionally, `index.ts` files are endpoints. Please see the [routing docs](https://qwik.builder.io/qwikcity/routing/overview/) for more info.

- `src/components`: Recommended directory for components.

- `public`: Any static assets, like images, can be placed in the public directory. Please see the [Vite public directory](https://vitejs.dev/guide/assets.html#the-public-directory) for more info.

## Add Integrations and deployment

Use the `npm run qwik add` command to add additional integrations. Some examples of integrations includes: Cloudflare, Netlify or Express Server, and the [Static Site Generator (SSG)](https://qwik.builder.io/qwikcity/guides/static-site-generation/).

```shell
npm run qwik add # or `yarn qwik add`
```

## Development

Development mode uses [Vite's development server](https://vitejs.dev/). The `dev` command will server-side render (SSR) the output during development.

```shell
npm start # or `yarn start`
```

> Note: during dev mode, Vite may request a significant number of `.js` files. This does not represent a Qwik production build.

## Preview

The preview command will create a production build of the client modules, a production build of `src/entry.preview.tsx`, and run a local server. The preview server is only for convenience to preview a production build locally and should not be used as a production server.

```shell
npm run preview # or `yarn preview`
```

## Production

The production build will generate client and server modules by running both client and server build commands. The build command will use Typescript to run a type check on the source code.

```shell
npm run build # or `yarn build`
```

## Node Server

This app has a minimal zero-dependencies server. Using the built-in `http.createServer` API.
This should be faster and less overhead than Express or other frameworks.

After running a full build, you can preview the build using the command:

```
npm run serve
```

Then visit [http://localhost:8080/](http://localhost:8080/)
