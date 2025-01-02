### Project Documentation Guide {#top}

Welcome to the documentation for this project! Here you’ll find step-by-step instructions to get started with the **Godot Tool** and the **Astro Webpage Generator**.

---
## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Godot Tool](#godot-tool)  
   2.1 [Setup](#setup-godot)  
   2.2 [Usage](#usage-godot)
3. [Astro Webpage Generator](#astro-webpage-generator)  
   3.1 [Setup](#setup-astro)  
   3.2 [Usage](#usage-astro)  
   3.3 [Common Issues](#common-issues-astro)
4. [Optional Optimizations](#optional-optimizations)
5. [Additional Resources](#additional-resources)

---

## 1. Prerequisites {#prerequisites}

Before you begin, ensure you have the following installed:

- [Godot Engine 4.x](https://godotengine.org/download)
- [Node.js](https://nodejs.org/) (recommended via [nvm](https://github.com/nvm-sh/nvm))
- [pnpm](https://pnpm.io/)

---

## 2. Godot Tool {#godot-tool}

The **Godot Tool** helps you generate previews of 3D models and a `.json` file containing detailed metadata about your asset pack.

### 2.1 Setup {#setup-godot}

1. **Download the Tool**:

   - From [GitHub](https://github.com/your-repo-link).
   - Or directly via the [Godot Asset Library](https://godotengine.org/asset-library).

2. **Open the Project**:

   - Launch Godot 4.x.
   - Open the `godot-tool/` directory.

3. **Configure Settings**:
   - Specify the output folder for previews.
   - Adjust metadata settings in the provided UI.

<p align="right"><a href="#top">Back to top 🔼</a></p>

---

### 2.2 Usage {#usage-godot}

1. **Load 3D Models**:

   - Drag and drop your `.glb`, `.obj`, or other supported formats into the tool. Place these models in the "models" folder.

2. **Render Previews**:

   - Adjust the camera or lighting if needed.
   - By clicking in the `Main Controller` element you will be able to select the resolution, padding and output directory of the images.

3. **Generate Metadata**:

   - Click the `Metadata Generator`.
   - Fill out details such as author, license, version, website, and description.

4. **Export**:
   - Run the project by clicking the `Play` icon.
   - Reveal the project documents and copy them to another folder.

<p align="right"><a href="#top">Back to top 🔼</a></p>

---

## 3. Astro Webpage Generator {#astro-webpage-generator}

The **Astro Webpage Generator** converts the previews and `.json` metadata into a static webpage for showcasing your asset pack.

### 3.1 Setup {#setup-astro}

1. **Install Node.js**:

   - Install Node.js (recommended via [nvm](https://github.com/nvm-sh/nvm)).

2. **Install `pnpm`**:

   ```sh
   npm install -g pnpm
   ```

3. **Clone the Repository**:

   ```sh
   git clone https://github.com/your-repo-link
   ```

4. **Navigate to the `astro-web/` Directory**:

   ```sh
   cd astro-web/
   ```

5. **Install Dependencies**:
   ```sh
   pnpm install
   ```

<p align="right"><a href="#top">Back to top 🔼</a></p>

---

### 3.2 Usage {#usage-astro}

1. **Add Previews and Metadata**:

   - Place `.png` preview images in `src/assets/images/`.
   - Place the `.json` metadata file in `src/data/`.

2. **Run the Development Server**:

   ```sh
   pnpm run dev
   ```

   This command will start a local server for previewing your webpage.

3. **Build the Static Site**:  
   Once you’re happy with your webpage:

   ```sh
   pnpm run build
   ```

   The output will be in the `dist/` directory.

4. **Deploy the Site**:  
   Upload the contents of the `dist/` folder to your hosting provider, such as GitHub Pages, Netlify, or Vercel.

<p align="right"><a href="#top">Back to top 🔼</a></p>

---

### 3.3 Common Issues {#common-issues-astro}

- **Issue**: Development server not starting.
  - **Solution**: Ensure all dependencies are installed correctly by running `pnpm install` again.

- **Issue**: Images not displaying.
  - **Solution**: Check that images are placed in the correct directory (`src/assets/images/`) and have the correct file extensions.

- **Issue**: You want to change the styles.
  - **Solution**: You can change the colors of the 
  ```css
  :root {
    /* Principal Colors */
    --color-background: #171b21;
    --color-surface: #1e242c;
    --color-surface-alt: #2f333a;
    --color-text-primary: #ffffff;
    --color-text-secondary: #d7d9da;
    --color-accent: #ffbe07;

    /* Shadows */
    --shadow-sm: 0px 1px 2px rgba(0, 0, 0, 0.7);
    --shadow-md: 0px 2px 4px rgba(0, 0, 0, 0.1);
    --shadow-lg: 0px 4px 6px rgba(0, 0, 0, 0.1);
  }
  ```



<p align="right"><a href="#top">Back to top 🔼</a></p>

---

## 4. Optional Optimizations {#optional-optimizations}

To optimize the images for deployment, use [XnConvert](https://www.xnview.com/en/xnconvert/) to remove metadata and reduce file size.

<p align="right"><a href="#top">Back to top 🔼</a></p>

---

## 5. Additional Resources {#additional-resources}

- **Godot Documentation**: [Learn more about Godot Engine](https://docs.godotengine.org/).
- **Astro Documentation**: [Astro Official Docs](https://docs.astro.build/).
- **pnpm Documentation**: [pnpm Official Docs](https://pnpm.io/).

<p align="right"><a href="#top">Back to top 🔼</a></p>