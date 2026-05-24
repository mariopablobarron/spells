import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const spells = defineCollection({
  loader: glob({ pattern: "**/*.mdx", base: "./src/content/spells" }),
  schema: z.object({
    title: z.string(),
    summary: z.string(),
    category: z.enum(["Cart", "Voice", "Admin", "Catalogue", "Form"]),
    difficulty: z.enum(["S", "M", "L"]),
    sourceProject: z.string().default("startidea-merch"),
    sourceUrl: z.string().url().optional(),
    publishedAt: z.coerce.date(),
    updatedAt: z.coerce.date().optional(),
    tags: z.array(z.string()).default([]),
  }),
});

export const collections = { spells };
