# MEL quantification

ImageJ/Fiji macros for quantifying marker expression level (MEL) in haematoxylin-DAB immunohistochemistry (IHC) images.

Within a user-defined tissue or region of interest, the workflow measures:

- the area occupied by a selected cellular compartment (nuclei, cytoplasm,
  or membrane); and
- the mean signal in the deconvolved DAB channel within that cellular compartment.

<div align="center">
  <table>
    <tr>
      <td align="center" bgcolor="#f6f8fa" style="border: 1px solid #d0d7de; border-radius: 8px; padding: 14px;">
        <img src="docs/figures/workflow_overview.png" alt="General workflow for MEL quantification" width="850">
        <br>
        <div style="background-color: #eaeef2; border-left: 4px solid #9bb8d8; color: #afc6e0; margin-top: 12px; padding: 9px 14px; text-align: left;">
          <strong>Workflow overview.</strong>
          From the original RGB IHC image to region definition, colour
          deconvolution, compartment segmentation and MEL quantification.
        </div>
      </td>
    </tr>
  </table>
</div>

## Repository structure

```text
MEL_quantification/
|-- README.md
|-- LICENSE
|-- docs/
|   `-- figures/
|       `-- workflow_overview.png
`-- MEL Quantification/
    |-- run_GUI.ijm
    |-- nuclei/
    |   |-- nuclear.ijm
    |   |-- nuclear_single.ijm
    |   |-- nuclear_ROI.ijm
    |   |-- nuclear_tissue.ijm
    |   `-- nuclear_whole_tissue.ijm
    |-- cytoplasm/
    |   |-- cytoplasm.ijm
    |   |-- cytoplasm_single.ijm
    |   |-- cytoplasm_ROI.ijm
    |   |-- cytoplasm_tissue.ijm
    |   `-- cytoplasm_whole_tissue.ijm
    `-- membrane/
        |-- membrane.ijm
        |-- membrane_single.ijm
        |-- membrane_ROI.ijm
        |-- membrane_tissue.ijm
        `-- membrane_whole_tissue.ijm
```

## What the method does

For each RGB IHC image, the workflow:

1. defines the region in which measurements are made;
2. separates haematoxylin and DAB with ImageJ's `H&E DAB` colour
   deconvolution vector;
3. segments the selected cellular compartment; and
4. measures compartment area and mean DAB intensity.

The method supports three cellular compartments: nuclei, cytoplasm and membrane.

## Measurement definition

For mask-based analyses, the area calculations are:

<div align="center">
  <p>
    <code>compartment area (μm<sup>2</sup>)</code>
    =
    <code>compartment area (pixels) × r<sup>2</sup></code>
  </p>
  <p>
    <code>compartment area (%)</code>
    =
    <code>100 × compartment area (μm<sup>2</sup>)</code>
    /
    <code>analysed-region area (μm<sup>2</sup>)</code>
  </p>
</div>

`r` is the image scale in micrometres per pixel. 

## Analysis modes

The launcher presents three choices:

| Choice | Options | Meaning |
|---|---|---|
| Analysis mode | Single image; Batch mode | Process one image or all matching images in a folder |
| Region to analyse | Whole tissue; ROI from mask; Manual ROI | Define the region used for cell segmentation and marker intensity measurement |
| Cell compartment | Nuclei; Cytoplasm; Membrane | Select the cell compartment to quantify |

Manual ROI is available only in single-image mode. The macro selected by
the launcher is determined by these choices:

| Filename suffix | Input | Region definition | Processing |
|---|---|---|---|
| `_whole_tissue` | One original image | Automatic tissue threshold | Single image |
| `_tissue` | Folder of original images | Automatic tissue threshold | Batch |
| `_single` | One original image and one label mask | External ROI mask | Single image |
| `_ROI` | One original image | Freehand ROI drawn by the user | Single image |
| No suffix | Folder of images and folder of label masks | External ROI mask | Batch |

## Algorithm

### Nuclei

The macro thresholds the deconvolved haematoxylin channel, fills holes,
applies a median filter, and uses watershed to separate touching objects.
`Analyze Particles` then excludes objects outside the configured minimum
and maximum areas. The resulting nuclear ROI is used to measure nuclear
area and DAB intensity.

### Cytoplasm

The macro detects nuclei using the nuclear workflow and dilates the
nuclear ROI. Boolean operations between the selected tissue/ROI region
and the dilated nuclei produce the cytoplasmic ROI. Cytoplasm area and
mean DAB intensity are then measured in that ROI.

### Membrane

The macro generates seeds from local maxima in the haematoxylin channel
and from maxima in strongly DAB-positive regions. It applies a
marker-controlled watershed to the inverted DAB-derived edge image inside
the selected region. Watershed boundaries are eroded and filtered by
minimum object size before membrane area and mean DAB intensity are
measured.

## Input data

### Original IHC image

The original image is the RGB brightfield image containing haematoxylin
and DAB staining. It is the image from which the DAB measurement is made.

Required conditions:

- RGB format compatible with the `H&E DAB` deconvolution vector;
- `.tif` extension for batch mode (the current macros check for lowercase
  `.tif`);
- the same pixel dimensions as its label mask when mask mode is used; and
- a known pixel scale supplied through `Ratio micra/pixel`.

Do not use a deconvolved channel, a binary nuclei mask, or a JPEG quality
control overlay as the original image.

### External label map

An external mask is required only for **ROI from mask** mode. It must be a label
image in which pixel values represent regions such as background and the
region of interest. This can be any ROI selected for analysis; a typical use
case is a segmented tumour region.

For batch mask analysis, image and mask files must have exactly the same
filename and extension and must be stored in separate parallel folders:

```text
images/
|-- case_001.tif
`-- case_002.tif

masks/
|-- case_001.tif
`-- case_002.tif
```

## Parameters

The following are the parameters exposed by the current macros. Defaults
are starting values encoded in the scripts, not universal biological
constants.

| Parameter | Used by | Function | Default |
|---|---|---|---:|
| `Ratio micra/pixel` (`r`) | All variants | Converts pixel areas to um^2 | 0.5 |
| `ROI label` (`roiLabel`) | Mask variants | Label selected as the region of interest after the internal subtraction | 1 |
| `Nuclei threshold` (`thBlue`) | Nuclei, cytoplasm | Upper threshold on the deconvolved haematoxylin channel | 190 nuclei; 100 cytoplasm |
| `Nuclei threshold` (`thBlue`) | Membrane | Upper threshold used for haematoxylin seed generation | 140 |
| `Min nuclei size` (`minCellSize`) | Nuclei, cytoplasm | Minimum accepted nuclear particle area in pixels | 30 |
| `Max nuclei size` (`maxCellSize`) | Nuclei, cytoplasm | Maximum accepted nuclear particle area in pixels | 15000 |
| `Prominence for nuclei detection` (`prominence`) | Membrane | Prominence used by `Find Maxima` for seeds | 5 |
| `GLUT threshold` (`thBrown`) | Membrane | Threshold for strongly DAB-positive seed regions | 130 |
| `Min membrane size` (`minMembSize`) | Membrane | Minimum accepted membrane particle area in pixels | 50 |

## Outputs

The three mask-based batch macros have an active file-based export:

- `MEL Quantification/nuclei/nuclear.ijm`;
- `MEL Quantification/cytoplasm/cytoplasm.ijm`; and
- `MEL Quantification/membrane/membrane.ijm`.

They append one row per analysed image to
`QuantificationResults.xls`. Depending on the compartment, the table
contains:

- `Label`: original image filename;
- `ROI area (um2)`: area of the selected region of interest;
- `Nuclei area in ROI (%)`, `Cytoplasm area in ROI (%)`, or
  `Membrane area in ROI (%)`;
- `Iavg nuclei`, `Iavg cytoplasm`, or `Iavg membrane`; and
- additional classification fields in variants that implement them.

The output folders are created inside the selected mask directory:

```text
Quantification_results/
|-- QuantificationResults.xls
`-- case_001_analyzed.jpg
```

For cytoplasm:

```text
Quantification_results_cytoplasmic/
|-- QuantificationResults.xls
`-- case_001_analyzed.jpg
```

For membrane:

```text
Membrane_segmentations/
`-- case_001_membraneSegmentation.jpg
```

The JPEG files are quality-control overlays with the detected compartment
drawn in red over the original image. They are output figures, not input
label masks.

### Requirements

- Fiji with a current ImageJ 1.x installation;
- the Fiji **Colour Deconvolution** command; and
- **Marker-controlled Watershed** for membrane analysis. If unavailable,
  enable the MorphoLibJ update site in `Help > Update... > Manage update
  sites`, install it, and restart Fiji.

### Installation

The runnable macros are inside the repository's `MEL Quantification/`
directory. Clone or download this repository, then copy that complete
directory into Fiji's `plugins` directory (do not copy the repository root
directory):

```text
MEL_quantification/MEL Quantification/  ->  Fiji.app/plugins/MEL Quantification/
```

The resulting installation must have this layout:

```text
Fiji.app/plugins/MEL Quantification/
|-- run_GUI.ijm
|-- nuclei/
|-- cytoplasm/
`-- membrane/
```

Restart Fiji. The launcher appears in the `Plugins` menu as **run_GUI**.
Select it to open the MEL quantification analysis interface.
