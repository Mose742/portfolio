# Moses Okumu · Data portfolio (Quarto + GitHub Pages)

Live site: https://mose742.github.io/portfolio/

## Structure

```
_quarto.yml          site settings, navbar, theme (light + dark)
index.qmd            home page: hero, featured data stories, design approach, KPIs
gallery.qmd          filterable chart gallery with full-screen viewer
projects/            one folder per case study, each with index.qmd + thumb.svg
  index.qmd          projects gallery (auto-built listing with filters)
skills.qmd           filterable toolkit
experience.qmd       timeline, education, certifications
contact.qmd          contact details + message form
assets/
  theme-light.scss   colours and fonts (light mode)
  theme-dark.scss    colours and fonts (dark mode)
  styles.css         layout, cards, timeline, animations
  site.html          small scripts: counters, typing effect, filters
  files/             CV PDF and other downloads
docs/                the rendered website, which GitHub Pages serves
```

## Edit and preview

1. Install [Quarto](https://quarto.org/docs/get-started/) and open this folder in RStudio, Positron or VS Code.
2. Run `quarto preview`. The site opens in your browser and refreshes as you save.

## Publish to GitHub Pages (first time)

1. Create a **public** repository called `portfolio` on github.com/mose742.
2. In this folder, run:
   ```
   quarto render
   git init
   git add .
   git commit -m "Portfolio v1"
   git branch -M main
   git remote add origin https://github.com/mose742/portfolio.git
   git push -u origin main
   ```
3. On GitHub, go to **Settings → Pages → Deploy from a branch**, choose `main` and `/docs`, then save.
4. After a minute or two the site is live at https://mose742.github.io/portfolio/

## Add a project

1. Copy any folder in `projects/` and rename it, for example `projects/kenya-education/`.
2. Edit its `index.qmd`: title, description, date, `order`, categories and body text.
3. Replace `thumb.svg` with your own image (16:9, e.g. 1600×900; `.png` or `.jpg` also work, so update `image:` to match).
4. Add the `Open data` category if the project is built on a public dataset.
5. Run `quarto render`, then `git add . && git commit -m "Add project" && git push`.

To feature a project on the home page, copy one of the `<a class="story">` blocks under "Featured data stories" in `index.qmd`.

## Add a chart to the gallery

Open `gallery.qmd` and copy one `<figure class="g-item">` block. Change `data-src` and `src` (image path), `data-title`, `data-sub`, `data-link` (its project page), and `data-tool` (`r` or `deneb`, or add a new filter button).

## Before publishing

- Replace `mosesokumu` in `_quarto.yml` and `contact.qmd`.
- Keep real programme data out of the site: rebuild dashboards on public or dummy data.
- The CV in `assets/files/` has the phone number and referee contacts removed on purpose.
